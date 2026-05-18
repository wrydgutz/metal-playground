# Gaussian Blur

Gaussian blur is like box blur, except nearby pixels contribute more weight than far pixels.

2D Gaussian formula:

$$G(x,y)=\frac{1}{2\pi\sigma^2}e^{-\frac{x^2+y^2}{2\sigma^2}}$$

Where:

- $x, y$ = offset from center
- $\sigma$ = blur spread
- Larger $\sigma$ → softer blur

The blurred pixel becomes:

$$C_{out}(x,y)=\frac{\sum_{i=-r}^{r}\sum_{j=-r}^{r} C_{in}(x+i,y+j)\cdot G(i,j)}{\sum_{i=-r}^{r}\sum_{j=-r}^{r} G(i,j)}$$

Compared to box blur:

- Box blur → equal weights
- Gaussian blur → weighted average
