rm -rf dist

nim c -d:release -o:OrificeCalculator --outdir:dist Standalone.nim
cp input.json ./dist/input.json

rm -rf port

nim js -d:nodejs -d:release --outdir:port/JS OrificeCalculator.nim
sed -i -e '2d' port/JS/OrificeCalculator.js
echo 'module.exports = orificeCalculator' >> port/JS/OrificeCalculator.js
