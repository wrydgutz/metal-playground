# Sharpen

Enhances edges and fine details by increasing the contrast between neighboring pixels.


### Convolution Matrix

Using the convolution matrix approach, the common sharpen kernel (or weight) is:

$$K = \begin{bmatrix}0 & -s & 0 \\ -s & 1 + 4s & -s \\ 0 & -s & 0\end{bmatrix}$$

Where $s$ is the sharpen strength.

Formula:

$$O(x, y) =
\sum_{i=-1}^{1}
\sum_{j=-1}^{1}
I(x+i, y+j)\cdot K(i,j)$$

Where:

* $K$ = sharpen kernel
* Center pixel gets boosted
* Neighboring pixels subtract detail around it
* Result enhances edges/details
