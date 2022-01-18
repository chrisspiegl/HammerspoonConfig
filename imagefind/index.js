import process from 'node:process';
import {Buffer} from 'node:buffer';
import {fileURLToPath} from 'node:url';
import path from 'node:path';
import cv from 'opencv4nodejs';
import {screen} from '@nut-tree/nut-js';
import jpg from '@julusian/jpeg-turbo';
import meow from 'meow'

const __dirname = path.dirname(fileURLToPath(import.meta.url));

const cli = meow({
  importMeta: import.meta,
})

const imgTarget = `${__dirname}/../targetImages/${cli.flags.target}`;

const timeStart = Date.now();
let timeLast = Date.now();
const debug = cli.flags.debug || false;

const log = function (...args) {
	if (debug) {
		console.log(...args);
	}
};

const screenGrabToBuffer = () => new Promise(async resolve => {
	const image = await screen.grab();
	const jpgOptions = {
		format: jpg.FORMAT_BGRA,
		width: image.width,
		height: image.height,
		subsampling: jpg.SAMP_444,
		quality: 50,
	};
	log('This took: ', Date.now() - timeLast, 'ms', 'before buffer conversion');
	const preallocated = Buffer.alloc(jpg.bufferSize(jpgOptions));
	return resolve({
    image: jpg.compressSync(image.data, preallocated, jpgOptions),
    pixelDensity: image.pixelDensity.scaleX,
  });
});

const findWaldo = async () => {
	const {image, pixelDensity} = await screenGrabToBuffer();
	log('This took: ', Date.now() - timeLast, 'ms', 'after screen capture');
	timeLast = Date.now();
	const originalMat = await cv.imdecode(image);
	const waldoMat = await cv.imreadAsync(imgTarget);
	log('This took: ', Date.now() - timeLast, 'ms', ' after openCV image loading');
	timeLast = Date.now();
	originalMat.correctMatches;
	const matched = originalMat.matchTemplate(waldoMat, cv.TM_CCORR_NORMED); // Cv.TM_CCORR_NORMED is the fastest and it is normalized to a range of 0-1
	log('This took: ', Date.now() - timeLast, 'ms', 'after openCV image match');
	timeLast = Date.now();
	const minMax = matched.minMaxLoc();
	const {maxVal, maxLoc: {x, y}} = minMax;
	const result = {
		found: maxVal > (cli.flags.minAccuracy || 0.9),
		accuracy: maxVal,
		x,
		y,
    pixelDensity
	};

	return result;

	// If (result.accuracy > 0.9) {
	//   console.log("MATCHING ☺️", );
	//   if (debug) {
	//     originalMat.drawRectangle(
	//       new cv.Rect(x, y, waldoMat.cols, waldoMat.rows),
	//       new cv.Vec(0, 255, 0),
	//       2,
	//       cv.LINE_8
	//     );

	//     cv.imshow('We\'ve found Waldo!', originalMat);
	//     cv.waitKey();
	//   }
	// } else {
	//   log('NO MATCH FOUND ❤️‍🔥');
	// }
};

(async () => {
	try {
		const result = await findWaldo();
		log('This took: ', Date.now() - timeStart, 'ms');
		console.log(JSON.stringify(result));
	} catch (error) {
		log('ERROR', error);
	}
})();

// TM_CCORR
