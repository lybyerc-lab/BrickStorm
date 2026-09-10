const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = 8080;
const WEB_DIR = path.join(__dirname, '..', 'build', 'web');

const MIME_TYPES = {
	'.html': 'text/html',
	'.js': 'text/javascript',
	'.wasm': 'application/wasm',
	'.pck': 'application/octet-stream',
	'.png': 'image/png',
	'.json': 'application/json',
	'.css': 'text/css'
};

const server = http.createServer((req, res) => {
	let reqPath = req.url.split('?')[0];
	if (reqPath === '/' || reqPath === '') {
		reqPath = '/index.html';
	}
	
	const filePath = path.join(WEB_DIR, reqPath);
	const ext = path.extname(filePath).toLowerCase();
	const contentType = MIME_TYPES[ext] || 'application/octet-stream';

	fs.readFile(filePath, (err, data) => {
		if (err) {
			res.writeHead(404, { 'Content-Type': 'text/plain' });
			res.end('404 Not Found');
			return;
		}

		// Cross-origin headers for WebAssembly & SharedArrayBuffer
		res.writeHead(200, {
			'Content-Type': contentType,
			'Cross-Origin-Opener-Policy': 'same-origin',
			'Cross-Origin-Embedder-Policy': 'require-corp',
			'Access-Control-Allow-Origin': '*'
		});
		res.end(data);
	});
});

server.listen(PORT, '0.0.0.0', () => {
	console.log(`\n=======================================================`);
	console.log(`  🌪️  BRICKSTORM WEB SERVER READY FOR MOBILE PLAY!     `);
	console.log(`=======================================================`);
	console.log(`- On this PC:             http://localhost:${PORT}`);
	console.log(`- On your Android phone:  http://192.168.170.81:${PORT}`);
	console.log(`=======================================================\n`);
});
