# Contrast

Shifts colors away from or toward the midpoint gray (0.5).

$C_{out} = (C_{in} - 0.5) \cdot c + 0.5$

Where:

- $C_{in}$ = input color
- $C_{out}$ = output color
- $c$ = contrast amount

Expanded:

- $c = 1.0$ → unchanged
- $c > 1.0$ → more contrast
- $0 < c < 1.0$ → flatter image

Per channel:

$$\begin{aligned}R' &= (R - 0.5)c + 0.5 \\ G' &= (G - 0.5)c + 0.5 \\ B' &= (B - 0.5)c + 0.5\end{aligned}$$
