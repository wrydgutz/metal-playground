# Laplacian Edge Detection

Laplacian Edge Detection highlights regions where image intensity changes rapidly using the second derivative of the image.

Unlike Sobel Edge Detection, which detects directional gradients, the Laplacian detects edges equally in all directions.


## Kernel

The Laplacian kernel is convolved over the image.

$$
K =
\begin{bmatrix}
0 & -1 & 0 \\
-1 & 4 & -1 \\
0 & -1 & 0
\end{bmatrix}
$$

## Sharpen

Laplacian sharpening uses the extracted edge detail to enhance the original image.

Current sharpening formula:

$$Sharpened = Original - \alpha \cdot Laplacian$$

