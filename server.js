var net = require('net');

var server = net.createServer(function(socket) {
	socket.write('Hello from server');
	//socket.pipe(socket)
	socket.on('data', function (data) {
		console.log(data);
		socket.write(data);
  	});
});

server.listen(8080, '192.168.1.9');