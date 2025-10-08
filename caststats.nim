#!/usr/bin/env -S nim r --hints:off
# -*- mode: nim -*-

# caststats.nim - Script that raises some interesting stats from a asciicast.

# Unfortunately nimscript doesn't seems to support streams
# So the file is named ".nim" for the Nim compiler to work

import std/[os, streams, json, tables]

type
  Event = tuple
    kind: string
    sec: float
  Stats = object
    eventsCount: Table[string, int] # event kind/count
    lastSec: float

proc extractEvents(strm: FileStream): seq[Event] =
  var line = strm.readLine
  while strm.readLine line:
    let event = line.parseJson
    result.add (
      kind: event[1].getStr,
      sec: event[0].getFloat
    ).Event

proc generateStats(events: seq[Event]): Stats =
  for event in events:
    if not result.eventsCount.hasKey event.kind:
      result.eventsCount[event.kind] = 1
    else:
      inc result.eventsCount[event.kind]
  result.lastSec = events[^1].sec

proc main(args: seq[string]): int =
  if args.len != 1:
    echo "Usage:"
    echo "  caststats [CAST FILE]"
    return 1

  let castFile = args[0]
  if castFile.len <= 0 or not castFile.fileExists:
    echo "Cast file doesn't exists"
    return 1

  var strm = castFile.newFileStream fmRead
  defer: strm.close()

  let
    events = strm.extractEvents
    stats = generateStats(events)

  echo %*stats

when isMainModule:
  quit main(commandLineParams())
