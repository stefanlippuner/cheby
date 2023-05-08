import cheby.tree as tree

access_map = {'rw': 'rw', 'ro': 'r', 'wo': 'w'}


def clean_string(desc):
    """Clean a description string so that it is OK for a CSV field"""
    if not desc:
        return desc
    # Keep only the first line
    l = desc.splitlines()[0]
    # Replace comma with spaces
    return str.replace(l, ',', ' ')


def clean_args(args, args_list, fmt_list):
    if args is None:
        return ''
    args_cleaned = []
    for arg, fmt in zip(args_list, fmt_list):
        val = args.get(arg)
        if val is not None:
            args_cleaned.append('{}={}'.format(
                arg.replace('-', '_'),
                fmt(val)
            ))
    return ' '.join(args_cleaned)


class CsvTable(object):
    def __init__(self, *titles):
        self.titles = titles
        self.widths = [len(t) for t in titles]
        self.rows = []

    def append(self, **row):
        self.rows.append(dict(**row))

    def count(self):
        return len(self.rows)

    def write(self, fd):
        for r in self.rows:
            for i, title in enumerate(self.titles):
                self.widths[i] = max(self.widths[i],
                                     len(str(r.get(title, ''))))

        for title, width in zip(self.titles, self.widths):
            if title == self.titles[-1]:
                fd.write(" {val}".format(val=title))
            else:
                fd.write(" {val:>{width}},".format(val=title, width=width))
        fd.write("\n")

        for r in self.rows:
            for title, width in zip(self.titles, self.widths):
                val = r.get(title, '')
                if title == self.titles[-1]:
                    if val:
                        fd.write(" {val}".format(val=val))
                else:
                    fd.write(" {val:>{width}},".format(val=val, width=width))
            fd.write("\n")

    def write_if_needed(self, fd):
        if self.count != 0:
            self.write(fd)


class LifTable(CsvTable):
    def __init__(self):
        super().__init__("hw_mod_name", "hw_lif_name", "hw_lif_vers", "edge_vers",
                         "bus", "endian", "description")

    def write(self, fd):
        fd.write("#LIF (Logical Interface) table definition\n")
        super().write(fd)
        fd.write("\n")


class ResourceTable(CsvTable):
    def __init__(self):
        super().__init__("res_def_name", "type", "res_no", "args", "description")

    def write(self, fd):
        fd.write("#Resources (Memory(BARs) - DMA - IRQ) table definition\n")
        super().write(fd)
        fd.write("\n")


class BlockInstTable(CsvTable):
    def __init__(self):
        super().__init__("block_inst_name", "block_def_name", "res_def_name",
                         "offset", "description")

    def write(self, fd):
        fd.write("#Block instances table definition\n")
        super().write(fd)
        fd.write("\n")


class IntcTable(CsvTable):
    def __init__(self):
        super().__init__("intc_name", "type", "reg_name", "block_def_name",
                         "chained_intc_name", "chained_intc_mask", "args",
                         "description")

    def write(self, fd):
        fd.write("#Interrupt Controller (INTC) table definition\n")
        super().write(fd)
        fd.write("\n")


class RolesTable(CsvTable):
    def __init__(self):
        super().__init__("reg_role", "reg_name", "block_def_name", "args")

    def write(self, fd):
        fd.write("#Register Roles table definition\n")
        super().write(fd)
        fd.write("\n")


class EdgeReg(object):
    def __init__(self, reg, block_def_name, name, offset, flags, depth, mask, desc):
        assert isinstance(reg, tree.Reg)
        self.reg = reg

        self.block_def_name = block_def_name
        self.type = 'REG'
        self.name = name
        self.offset = hex(reg.c_address + offset)
        self.rwmode = access_map[reg.access]
        self.dwidth = tree.BYTE_SIZE * reg.c_size
        self.depth = hex(depth)
        self.mask = hex(mask) if mask is not None else ''
        self.flags = flags
        self.description = clean_string(desc) or ''

    def write(self, fd, encore):
        for title, width in zip(encore.block_titles, encore.block_col_widths):
            val = getattr(self, title, '')
            if title == 'description':
                if val:
                    fd.write(" {val}".format(val=val))
            else:
                fd.write(" {val:>{width}},".format(val=val, width=width))
        fd.write("\n")


class EncoreBlock(object):
    def __init__(self, block_name, encore):
        self.block_name = block_name
        self.regs = []
        self.encore = encore
        if block_name not in encore.blocks_set:
            encore.blocks.append(self)
            encore.blocks_set.add(block_name)

    def append_reg(self, reg, name, offset, flags='', depth=1, desc=None):
        self.regs.append(EdgeReg(reg, self.block_name, name,
                                 offset, flags, depth, None, desc or reg.description))
        if reg.has_fields():
            for f in reg.children:
                if not f.get_extension('x_driver_edge', 'generate', True):
                    continue
                if f.hi is None:
                    mask = 1
                else:
                    mask = (2 << (f.hi - f.lo)) - 1
                mask = mask << f.lo
                self.regs.append(EdgeReg(reg, self.block_name, "{}_{}".format(name, f.name),
                                         offset, flags, depth, mask, f.description))

    def append_block(self, blk, name, offset, desc):
        self.regs.append(EdgeBlockInst(blk, self.block_name, name, offset, desc))

    def write(self, fd):
        fd.write("#Block table definition\n")
        for title, width in zip(self.encore.block_titles, self.encore.block_col_widths):
            if title == 'description':
                fd.write(" {val}".format(val=title))
            else:
                fd.write(" {val:>{width}},".format(val=title, width=width))
        fd.write("\n")

        for r in self.regs:
            r.write(fd, self.encore)


class EdgeBlockInst(EdgeReg):
    def __init__(self, block, block_def_name, name, offset, desc):
        assert isinstance(block, EncoreBlock)
        self.block = block

        self.block_def_name = block_def_name
        self.type = self.block.block_name
        self.name = name
        self.offset = hex(offset)
        self.description = clean_string(desc) or ''


class Encore(object):
    def __init__(self):
        self.blocks_set = set()
        self.blocks = []
        self.top = None
        self.block_titles = ["block_def_name", "type", "name", "offset",
                             "rwmode", "dwidth", "depth", "mask", "flags",
                             "description"]
        self.block_col_widths = [len(t) for t in self.block_titles]

    def write(self, fd):
        top_needed = any([not isinstance(c, EdgeBlockInst) for c in self.top.regs])

        # Determine maximum width of each column across all blocks
        for b in self.blocks:
            for r in b.regs:
                for i, title in enumerate(self.block_titles):
                    self.block_col_widths[i] = max(self.block_col_widths[i],
                                                   len(str(getattr(r, title, ''))))
        # Write all blocks
        for b in self.blocks:
            if b == self.top:
                continue
            b.write(fd)
            fd.write('\n')
        if top_needed:
            self.top.write(fd)
            fd.write('\n')

        binst_table = BlockInstTable()
        if top_needed:
            binst_table.append(block_inst_name=self.top.block_name, block_def_name=self.top.block_name,
                               res_def_name="Registers", offset=0, description="Top level")
        else:
            for b in self.top.regs:
                binst_table.append(block_inst_name=b.name, block_def_name=b.block.block_name,
                                   res_def_name="Registers", offset=b.offset, description=clean_string(b.description))
        binst_table.write(fd)

        # Deal with roles and interrupt controllers
        intc_table = IntcTable()
        roles_table = RolesTable()

        for b in self.blocks:
            for r in filter(lambda x: type(x) == EdgeReg, b.regs):
                for intc in filter(None, map(lambda x: x.get('interrupt-controller'),
                                             r.reg.get_extension('x_driver_edge', 'interrupt-controllers', []))):
                    intc_name = intc['name']
                    intc_type = intc['type']

                    if intc_type not in ('INTC_SR', 'INTC_CR'):
                        raise AssertionError("unknown interrupt-controller type {}".format(intc_type))

                    chained = intc.get('chained')
                    if chained is not None:
                        chained_name = chained['name']
                        chained_mask = hex(chained['mask'])
                    else:
                        chained_name = ''
                        chained_mask = ''

                    args = clean_args(intc.get('args'), ('enable-mask', 'ack-mask'), (hex, hex))
                    desc = clean_string(intc.get('description', ''))

                    intc_table.append(intc_name=intc_name, type=intc_type, reg_name=r.name,
                                      block_def_name=r.block_def_name, chained_intc_name=chained_name,
                                      chained_intc_mask=chained_mask, args=args, description=desc)

                reg_role = r.reg.get_extension('x_driver_edge', 'reg-role')
                if reg_role:
                    role = reg_role['type']
                    args = reg_role.get('args', {})

                    if role == 'IRQ_V' or role == 'IRQ_L':
                        args_str = ''
                    elif role == 'ASSERT':
                        args_str = clean_args(args, ('min-val', 'max-val'), (hex, hex))
                    else:
                        raise AssertionError("unknown reg-role {}".format(role))

                    roles_table.append(reg_role=role, reg_name=r.name,
                                       block_def_name=r.block_def_name, args=args_str)

        intc_table.write_if_needed(fd)
        roles_table.write_if_needed(fd)


def process_body(b, n, offset, name_prefix=[]):
    for el in n.children:
        if not el.get_extension('x_driver_edge', 'generate', True):
            continue

        el_name_prefix = name_prefix + [el.name]
        el_name = '_'.join(el_name_prefix)

        el_addr = offset + el.c_address

        if isinstance(el, tree.Reg):
            b.append_reg(el, el_name, offset)

        elif isinstance(el, tree.Memory):
            flags = ''
            if el.get_extension('x_driver_edge', 'fifo', False):
                flags = 'FIFO'
            b.append_reg(el.children[0], el_name, el_addr, flags, el.c_depth, el.description)

        elif isinstance(el, tree.Repeat):
            if len(el.children) == 1 and isinstance(el.children[0], tree.Reg):
                b.append_reg(el.children[0], el_name, el_addr, '', el.count, el.description)
            else:
                # TODO
                b2 = EncoreBlock(el_name, b.encore)
                process_body(b2, el, 0)
                for i in range(0, el.count):
                    b.instantiate("{}_{}".format(el_name, i), b2, offset + el.c_abs_addr + i * el.c_elsize)

        elif isinstance(el, (tree.Block, tree.Submap)):
            if isinstance(el, tree.Submap):
                if el.filename is None:
                    # TODO
                    continue

                name = el.c_submap.name
                node = el.c_submap
                include = el.include
            else:
                name = el.name
                node = el
                include = False

            include = el.get_extension('x_driver_edge', 'include', include)
            block_prefix = el.get_extension('x_driver_edge', 'block-prefix', True)

            if include:
                process_body(b, node, el_addr, el_name_prefix if block_prefix else name_prefix)
            else:
                b2 = EncoreBlock(name, b.encore)
                b.append_block(b2, el_name, el_addr, el.description)
                process_body(b2, node, 0)

        else:
            raise AssertionError("unhandled element {}".format(type(el)))


def generate_edge3(fd, root):
    e = Encore()
    b = EncoreBlock("Top", e)
    e.top = b
    process_body(b, root, 0)

    fd.write("#Encore Driver GEnerator version: 3.0\n\n")

    lif_table = LifTable()
    lif_table.append(hw_mod_name=root.name, hw_lif_name=root.name.lower(),
                     hw_lif_vers="3.0.1", edge_vers="3.0", bus="VME",
                     endian="BE", description=clean_string(root.description))
    lif_table.write(fd)

    # TODO: args
    rsrc_table = ResourceTable()
    rsrc_table.append(res_def_name="Registers", type="MEM", res_no=0,
                      args="", description="")
    rsrc_table.write(fd)

    e.write(fd)