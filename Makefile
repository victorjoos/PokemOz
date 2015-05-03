ARGS = -s5 -d50 -p30 --map Map.txt
main.oza : main.oz PortObject.ozf Widget.ozf LibImg.ozf
	ozc -c main.oz -o main.oza
PortObject.ozf : port_object.oz AnimatePort.ozf AI.ozf Widget.ozf PortDefinitions.ozf
	ozc -c port_object.oz -o PortObject.ozf
AnimatePort.ozf : animate_port.oz Widget.ozf PortDefinitions.ozf
	ozc -c animate_port.oz -o AnimatePort.ozf
Widget.ozf : widget.oz PortDefinitions.ozf
	ozc -c widget.oz -o Widget.ozf
PortDefinitions.ozf : definitions_port.oz
	ozc -c definitions_port.oz -o PortDefinitions.ozf
AI.ozf : AI.oz PortDefinitions.ozf Widget.ozf
	ozc -c AI.oz -o AI.ozf
LibImg.ozf : make_lib.oz
	ozc -c make_lib.oz
	ozengine make_lib.ozf
lib : LibImg.ozf
	@echo done
run : main.oza lib
	ozengine main.oza $(ARGS)
clean :
	rm -rf PortObject.ozf AnimatePort.ozf Widget.ozf PortDefinitions.ozf AI.ozf
cleanall : clean
	rm -rf main.oza LibImg.ozf
