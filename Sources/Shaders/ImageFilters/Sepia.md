# Sepia

Gives an image a warm brown vintage look by remapping its colors using weighted mixes of the original red, green, and blue channels.

$$\mathbf{x} = \begin{bmatrix} r \\ g \\ b \end{bmatrix}$$

$$
\mathbf{y} = saturate(A\mathbf{x}, 0, 1),
\quad
A =
\begin{bmatrix}
0.393 & 0.769 & 0.189 \\
0.349 & 0.686 & 0.168 \\
0.272 & 0.534 & 0.131
\end{bmatrix}
$$
