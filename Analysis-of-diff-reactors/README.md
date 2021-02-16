This project was developed for the Chemical Reactor Design class.
The goal is to compare a Plug Flow Reactor (PFR) vs a Continuous Stirred-Tank Reactor (CSTR) for the Hydrolisis of Hemicellulose.
The product of the hydrolisis from Hemicellulose, found in large quantities on agricultural waste (wheat and rice straw or even corn cobs) is Xylose, currently used to produce Ethanol. 

The parameters to evaluate on each reactor are:
- % Hemicelulose that reacted
- Xylose yield
- Furfural (by-product, reaction inhibitor) yield
- Volume of each type of reactor
- Energy required to run these reactors

A .pdf document was added to the repo with the whole background and procedures in Spanish. 

The CSTRm.m and PFRm.m files contains the modelling for each reactor type.
The method used to solve all the diff. equations was ode23.

Project conclusion:

PFR reactor yields Xylose in higher concentrations than CSTR and because of the way PFR works, by-products are minimal.
The selected PFR has a diameter of 4" and a volume of 1 m^3.


