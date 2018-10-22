import lx, modo, karl_kit, xml.etree.ElementTree, os, sys

class StartupCommandClass(karl_kit.CommanderClass):
    _commander_default_values = []

    def commander_execute(self, msg, flags):
        # retrieve current kit path
        lxserv_path = os.path.dirname(os.path.realpath(__file__))
        new_kitpath = os.path.dirname(lxserv_path)
        tmp_file = os.path.join(new_kitpath, "tmp.xml")

        if not os.path.isfile(tmp_file):
            lx.eval('karl_kit.setup')
            return

        tmp_xml = xml.etree.ElementTree.parse(tmp_file).getroot()
        elements = tmp_xml.getchildren()

        values = dict()
        for element in elements:
            values[element.attrib['key']] = element.text

        if values["initialize"] == "1":
            lx.eval('karl_kit.cleanup')

lx.bless(StartupCommandClass, 'karl_kit.startup')
