Ewatcher is an ebay bidding monitor written in pure bash using [dominictarr][]'s [JSON.sh][].

# Installation #

Ensure that [dominictarr][]'s [JSON.sh][] is executable and present in either

  * one of the `$PATH` directories,
  * the same directory as the script.

# Usage #

Invoke the script with either the id or the url of an ebay auction:

```
$ ewatcher.sh http://www.ebay.com/itm/3ds-xl-bundle-/321632428356
2015/01/04 01:00:02 – US $230.00 (a***r), 3m 27s left
2015/01/04 01:00:37 – US $232.50 (2***s), 3m 01s left
2015/01/04 01:01:04 – US $235.00 (a***r), 2m 15s left
2015/01/04 01:01:47 – US $240.00 (a***r), 2m 02s left
2015/01/04 01:02:01 – US $245.00 (a***r), 1m 54s left
2015/01/04 01:02:10 – US $249.00 (a***r), 1m 05s left
2015/01/04 01:02:59 – US $251.50 (2***s), winner
```

When the file descriptor 3 is open, it will receive raw price updates:

```bash
$ exec 4>&1; ewatcher.sh 261907474113 3>&1 1>&4 |
>   while read p; do notify-send "$p"; done
```

 [dominictarr]: https://github.com/dominictarr
 [JSON.sh]: https://github.com/dominictarr/JSON.sh
