Ewatcher is an ebay bidding watcher written in pure bash using [dominictarr][]'s [JSON.sh][].

# Usage #

Invoke the script with either the id or the url of an auction:

```
$ ./ewatcher.sh http://www.ebay.com/itm/3ds-xl-bundle-/321632428356
Watching bids for auction #321632428356:
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
