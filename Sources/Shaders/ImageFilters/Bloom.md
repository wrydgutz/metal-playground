# Bloom

A multipass effect that creates a soft glow around bright areas by extracting highlights, blurring them, then combining them back with the original image.


## Pipeline

1. Bright Pass
2. Gaussian Blur
3. Combine With Original


### Bright Pass

Extract only pixels above a brightness threshold.

$$B(x,y)=\begin{cases}I(x,y),&L(x,y)>T\\0,&\text{otherwise}\end{cases}$$

Where:

* $I(x,y)$ = original pixel
* $L(x,y)$ = luminance
* $T$ = threshold


### Gaussian Blur

Blurs the Bright Pass's output. Uses the two-pass version to improve performance. 


### Combine Pass

Add the blurred highlights back to the original image.

$$O(x,y)=I(x,y)+k\cdot G(x,y)$$

Where:

* $O(x,y)$ = final output
* $I(x,y)$ = original image
* $G(x,y)$ = blurred bright texture
* $k$ = bloom intensity
