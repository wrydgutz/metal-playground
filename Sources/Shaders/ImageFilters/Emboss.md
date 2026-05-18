# Emboss

Emboss highlights directional intensity changes to create a raised or engraved 3D-like relief effect.

## Standard Zero-Sum Emboss Kernel

$$K = \begin{bmatrix} -2 & -1 & 0 \\ -1 & 0 & 1 \\ 0 & 1 & 2 \end{bmatrix}$$

- Kernel sum = 0
- Preserves no overall brightness
- Produces strong directional edge relief
- Common “standard emboss” baseline

## Formula

$$O(x, y) = \sum_{i=-1}^{1} \sum_{j=-1}^{1} I(x+i, y+j)\cdot K(i,j)$$

Where:

- $I(x,y)$ = input pixel
- $O(x,y)$ = output pixel
- $K$ = emboss kernel
