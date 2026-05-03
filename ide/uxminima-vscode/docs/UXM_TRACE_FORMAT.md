# UX-MINIMA Trace Format

Trace NDJSON formatındadır. Her satır JSON nesnesidir.

Örnek:

```json
{"step":1,"ip":1,"op":"RIGHT","ptr":1,"sp":0,"fifo_count":0,"status":0,"flags":128,"current":0}
```

Extension içi interpreter daha zengin snapshot üretir:

```json
{
  "step": 5,
  "ip": 3,
  "op": "META",
  "ptr": 2,
  "sp": 0,
  "fifo_count": 1,
  "status": 0,
  "flags": 640,
  "current": 90,
  "tape": [{"index":0,"value":65,"ascii":"A"}],
  "stack": [],
  "fifo": [{"index":0,"value":65,"ascii":"A"}],
  "data": [],
  "output": "A"
}
```
