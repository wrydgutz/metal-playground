# Grayscale

Removes color from an image by converting each pixel into a single luminance value representing its brightness.

## Rec.601

Rec.601 (Recommendation 601) is a luminance standard that converts RGB colors into grayscale brightness using weighted values that match human perception, giving more importance to green than red or blue.

$$\mathbf{x} = \begin{bmatrix} r \\ g \\ b \end{bmatrix}$$

$$
y = \mathbf{w}^\top \mathbf{x},
\quad
\mathbf{w} =
\begin{bmatrix}
0.299 \\
0.587 \\
0.114
\end{bmatrix}
$$
