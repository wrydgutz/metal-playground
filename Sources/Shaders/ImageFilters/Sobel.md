# Sobel Edge Detection

Detects edges by measuring how rapidly pixel intensity changes horizontally and vertically.

The image is first converted to grayscale, then two convolution kernels are applied:

Compute gradients at pixel $(x,y)$:

$$G_x(x,y) = \sum_{i=-1}^{1}\sum_{j=-1}^{1} I(x+i, y+j)\,K_x(i,j)$$

$$G_y(x,y) = \sum_{i=-1}^{1}\sum_{j=-1}^{1} I(x+i, y+j)\,K_y(i,j)$$

Then edge magnitude (two common choices):

- Exact magnitude:
$$M(x,y) = \sqrt{G_x(x,y)^2 + G_y(x,y)^2} $$
- Faster approximation:
$$M(x,y) \approx |G_x(x,y)| + |G_y(x,y)|$$

#### Notes
* Large magnitude = strong edge
* Small magnitude = flat region
