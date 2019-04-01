#! /usr/bin/env python
import numpy as np
import math as m
import matplotlib.pyplot as plt

xv = np.arange(0., 27., 0.2)

yv = xv

fig = plt.figure()
ax = fig.gca()
#ax.set_yscale('log')
#ax.set_xscale('log')
#ax.set_title("Mesures TOGA-COARE")
ax.set_xlabel("Vitesse du vent (m/s)")
ax.set_ylabel("Puissance (kW)")
plt.grid()

# now, plot the data:
plt.plot(xv, yv)
plt.show()
