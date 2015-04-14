main.oza : main.oz PortObject.ozf AnimatePort.ozf Widget.ozf
	ozc -c main.oz -o main.oza
PortObject.ozf : port_object.oz
	ozc -c port_object.oz -o PortObject.ozf
AnimatePort.ozf : animate_port.oz PortObject.ozf Widget.ozf
	ozc -c animate_port.oz -o AnimatePort.ozf
Widget.ozf : widget.oz
	ozc -c widget.oz -o Widget.ozf
run : main.oza
	ozengine main.oza
clean :
	rm PortObject.ozf
	rm AnimatePort.ozf
	rm Widget.ozf
