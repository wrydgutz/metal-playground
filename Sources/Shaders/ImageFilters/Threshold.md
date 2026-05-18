# Threshold

Converts an image into a binary-style image by setting pixels above a chosen brightness
value to one color (usually white) and pixels below it to another (usually black).

$$C_{out}=\begin{cases}1 & \text{if } C_{in} \ge t \\ 0 & \text{if } C_{in} < t\end{cases}$$

Where:

- $C_{in}$ = input value
- $C_{out}$ = output value
- $t$ = threshold

First, convert the image to luminance:

$$L = 0.299R + 0.587G + 0.114B$$

Then, apply the threshold to that luminance.
