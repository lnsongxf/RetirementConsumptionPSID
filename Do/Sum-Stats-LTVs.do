* TODO: try more robust SEs
* Look at consumption w/out the panel aspect -> better SEs?
* Look at food consumption

* Look at LTV at purchase




drop LTV

* I think this is the best way to compute LTV
gen LTV = (mortgage1 + mortgage2) / housevalue if t_homeownership == 0
* Better than this option gen LTV = ( housevalue - homeequity) / housevalue which I am guessing suffers from PSID imputation

* Maybe I should ignore the people who have LTV == 0?
sum LTV if t_homeownership == 0 & LTV <= 2 & LTV > 0, detail

sum LTV if t_homeownership == 0  & mortgage1 > 0, detail
* reg LTV i.wave if t_homeownership == 0 , nocon
reg LTV i.wave if t_homeownership == 0 & mortgage1 > 0, nocon




* Muelbauer reports that LTVs for first time home buyers rose from 85% in 1990 to 87.5 in 2000 to around 92.5% around 2005
* http://onlinelibrary.wiley.com/doi/10.1111/j.1468-0297.2011.02424.x/epdf

* Derived from the American Housing Survey (AHS), this series
* implies that down-payment constrain ts were eased early this decade (Figure 1), in line
* with Doms and KrainerÕs (2007) finding that homeownership rates rose among the
* young.

* NOTE: the AHS also has info on the source of down payment
* But they ask if of all people (no matter how long youve owned the house)
* So when looking online, obviously the big source of DP comes from previous sale
* https://www.census.gov/content/dam/Census/programs-surveys/ahs/data/2011/h150-11.pdf
* Could take a look at first time home buyers -- what are their sources?
* Probably mostly "Savings or cash on hand"
* Note: could also look at refi prevalence using this data
* Though dunno if that's useful
