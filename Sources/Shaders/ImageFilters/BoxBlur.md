# Box Blur

Smooths an image by replacing each pixel with the average of its surrounding neighboring pixels inside a fixed-size square region.

For a blur radius $r$:

$$C_{out}(x,y)=\frac{1}{(2r+1)^2}\sum_{i=-r}^{r}\sum_{j=-r}^{r} C_{in}(x+i,y+j)$$

Where:

- $(x, y)$ = current pixel
- $r$ = blur radius
- Kernel size = $(2r+1)^2$

Example:

- $radius = 1 → 3 \times 3$
- $radius = 2 → 5 \times 5$

A 3×3 blur means:

$$C_{out}=\frac{1}{9}\sum_{i=-1}^{1}\sum_{j=-1}^{1} C_{in}(x+i,y+j)$$
