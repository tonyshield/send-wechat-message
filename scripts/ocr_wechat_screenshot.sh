#!/usr/bin/env bash
set -euo pipefail

json_mode=0

if [ "${1:-}" = "--json" ]; then
  json_mode=1
  shift
fi

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 [--json] <image.png>" >&2
  exit 1
fi

image_path="$1"

if [ ! -f "$image_path" ]; then
  echo "Image not found: $image_path" >&2
  exit 1
fi

osascript -l JavaScript - "$image_path" "$json_mode" <<'JXA'
ObjC.import('Foundation')
ObjC.import('Vision')
ObjC.import('CoreImage')

function toNumber(value) {
  return Number(ObjC.unwrap(value))
}

function writeStdout(text) {
  const payload = $(String(text)).dataUsingEncoding($.NSUTF8StringEncoding)
  $.NSFileHandle.fileHandleWithStandardOutput.writeData(payload)
}

function scriptArgs() {
  const args = $.NSProcessInfo.processInfo.arguments
  const values = []
  for (let i = 0; i < Number(args.count); i++) {
    values.push(ObjC.unwrap(args.objectAtIndex(i)))
  }
  return values.slice(4)
}

function main(argv) {
  const imagePath = argv[0]
  const jsonMode = argv[1] === '1'
  const imageURL = $.NSURL.fileURLWithPath(imagePath)
  const ciImage = $.CIImage.imageWithContentsOfURL(imageURL)

  if (!ciImage || ObjC.unwrap(ciImage.isNull ? ciImage.isNull() : false)) {
    throw new Error('Could not load image for OCR: ' + imagePath)
  }

  const handler = $.VNImageRequestHandler.alloc.initWithCIImageOptions(ciImage, $({}))
  const request = $.VNRecognizeTextRequest.alloc.init
  request.recognitionLevel = $.VNRequestTextRecognitionLevelAccurate
  request.usesLanguageCorrection = true
  request.recognitionLanguages = $(['zh-Hans', 'en-US'])

  const ok = handler.performRequestsError($.NSArray.arrayWithObject(request), null)
  if (!ok) {
    throw new Error('Vision OCR failed for image: ' + imagePath)
  }

  const items = []
  const results = request.results
  const count = results ? Number(results.count) : 0

  for (let i = 0; i < count; i++) {
    const observation = results.objectAtIndex(i)
    const candidates = observation.topCandidates(1)
    if (!candidates || Number(candidates.count) === 0) {
      continue
    }

    const candidate = candidates.objectAtIndex(0)
    const text = ObjC.unwrap(candidate.string).trim()
    if (!text) {
      continue
    }

    const box = observation.boundingBox
    items.push({
      text,
      x: toNumber(box.origin.x),
      y: toNumber(box.origin.y),
      w: toNumber(box.size.width),
      h: toNumber(box.size.height)
    })
  }

  items.sort((left, right) => {
    const yDelta = right.y - left.y
    if (Math.abs(yDelta) > 0.003) {
      return yDelta
    }
    return left.x - right.x
  })

  if (jsonMode) {
    writeStdout(JSON.stringify(items, null, 2) + '\n')
    return
  }

  for (const item of items) {
    writeStdout(item.text + '\n')
  }
}

main(scriptArgs())
JXA
