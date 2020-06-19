rm -rf dist

nim c -d:release -o:OrificeCalculator --outdir:dist Standalone.nim
cp input.json ./dist/input.json

rm -rf port

nim js -d:nodejs -d:release --outdir:port/JS src/orificeCalculator.nim
sed -i -e '2d' port/JS/orificeCalculator.js
echo 'module.exports = orificeCalculator' >> port/JS/orificeCalculator.js
