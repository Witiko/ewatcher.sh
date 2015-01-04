# Introduction #

Ewatcher is a lightweight ebay bidding watcher written in pure bash using [dominictarr][]'s [JSON.sh][] script and an undocumented ebay json http api.

# Usage #

Simply invoke the script with either the id or the url of the auction:

```
$ ./ewatcher.sh 'http://www.ebay.com/itm/3ds-xl-bundle-/321632428356?pt=Video_Games&hash=item4ae2c96144'
Watching bids for auction #321632428356:
2015/01/04 00:58:15 – US $192.50 (a***r), 5m 32s left
2015/01/04 00:58:37 – US $197.50 (a***r), 5m 14s left
2015/01/04 00:58:54 – US $202.50 (a***r), 5m 06s left
2015/01/04 00:59:04 – US $210.00 (a***r), 4m 56s left
2015/01/04 00:59:08 – US $217.50 (a***r), 4m 48s left
2015/01/04 00:59:17 – US $220.00 (a***r), 4m 29s left
2015/01/04 00:59:34 – US $225.00 (a***r), 4m 01s left
2015/01/04 01:00:02 – US $230.00 (a***r), 3m 27s left
2015/01/04 01:00:37 – US $232.50 (2***s), 3m 01s left
2015/01/04 01:01:04 – US $235.00 (a***r), 2m 15s left
2015/01/04 01:01:47 – US $240.00 (a***r), 2m 02s left
2015/01/04 01:02:01 – US $245.00 (a***r), 1m 54s left
2015/01/04 01:02:10 – US $249.00 (a***r), 1m 05s left
2015/01/04 01:02:59 – US $251.50 (2***s), winner
```

[dominictarr]: https://github.com/dominictarr
[JSON.sh]: https://github.com/dominictarr/JSON.sh
