# Unsharp Mask

Sharpening technique that blurs the image, extracts the lost detail, then adds that detail back to the original image to enhance edges.

## Formula

### Detail Mask

$$M = I - B$$

Where:

* $I$ = original image
* $B$ = blurred image
* $M$ = extracted detail/high-frequency mask

### Final Image

$$S = I + aM$$

Equivalent to:

$$S = I + a(I - B)$$

Where:

* $a$ = sharpening amount
* $S$ = sharpened image
