********************************************************************************
************************************* DAILY ************************************
********************************************************************************

{

*********************************** CLEANING ***********************************

* Import the working database.
clear


*===============================================================================
* Complete with the file path to the daily data set.
*===============================================================================
import excel "", firstrow

*===============================================================================
* Set the working directory.
*===============================================================================
cd ""

* Rename the date variable for consistency with the code.
format date %tdDD/NN/CCYY
rename date Date

* Declare data to be time-series.
tsset Date, daily

* Label accordingly variables.
label variable Month_1 "January"
label variable Month_2 "February"
label variable Month_3 "March"
label variable Month_4 "April"
label variable Month_5 "May"
label variable Month_6 "June"
label variable Month_7 "July"
label variable Month_8 "August"
label variable Month_9 "September"
label variable Month_10 "October"
label variable Month_11 "November"
label variable Month_12 "December"

label variable Day_1 "Sunday"
label variable Day_2 "Monday"
label variable Day_3 "Tuesday"
label variable Day_4 "Wednesday"
label variable Day_5 "Thursday"
label variable Day_6 "Friday"
label variable Day_7 "Saturday"

label variable TimeTrend "Linear Time Trend"

label variable heating "Heating Consumption"
label variable baseload "Baseload Consumption"

* Initialize grouping variables that will be needed for the regressions to distinguish between the two different subsamples.
gen byte sample_pre_crisis = Date < td("01/12/2021")
gen byte sample_crisis = Date >= td("01/12/2021")




************************* REGRESSION: TOTAL CONSUMPTION ************************

* Model for Total Consumption, pre-crisis sample.
* ARDL.
* ardl RDS HDD SNSR price_l3m if sample_pre_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) maxlags(20) maxcombs(1000000)
ardl RDS HDD SNSR price_l3m if sample_pre_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) lags(15 8 1 1) 
eststo model0

* ECM.
ardl RDS HDD SNSR price_l3m if sample_pre_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) ec lags(15 8 1 1)
eststo model1

estat ectest



* Model for Total Consumption, crisis sample.
* ARDL.
* ardl RDS HDD SNSR price_l3m if sample_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) maxlags(20) maxcombs(1000000)

ardl RDS HDD SNSR price_l3m if sample_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) lags(9 8 1 0)
eststo model2

* ECM.
ardl RDS HDD SNSR price_l3m if sample_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) ec lags(9 8 1 0)
eststo model3

estat ectest



* Export regression tables.
esttab model0 model2 using "ARDL_RDS_DAILY.tex", replace b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) scalars(r2) label mtitle("Pre-Crisis Sample" "Crisis Sample") collabels(none) drop(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) varlabels(RDS "Demand" HDD "Heating‐Degree Days" SNSR "Solar Radiation" price_l3m "Lagged Price Index" _cons "Constant" date "Time Trend") compress sfmt(3 0) postfoot("\midrule" "Daily Seasonal Dummies & Yes & Yes \\" "Monthly Seasonal Dummies & Yes & Yes \\")

esttab model1 model3 using "EMC_RDS_DAILY.tex", replace b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) scalars(r2) label mtitle("Pre-Crisis Sample" "Crisis Sample") collabels(none) drop(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) compress sfmt(3 0) postfoot("\midrule" "Daily Seasonal Dummies & Yes & Yes &\\" "Monthly Seasonal Dummies & Yes & Yes \\")


esttab model1 model3 using "EMC_RDS_TABLE.tex", replace b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) scalars(r2) label mtitle("Pre-Crisis ECM" "Crisis ECM") collabels(none) keep(HDD L.RDS SNSR price_l3m) compress sfmt(3 0) varlabels(L.RDS "Demand" HDD "Heating‐Degree Days" SNSR "Solar Radiation" price_l3m "Lagged Price Index")



************************** TESTS: CRISIS vs PRE-CRISIS *************************

* Test whether the price coefficient estimated on the crisis subsample is different from the one estimated on the pre-crisis subsample: Wald test.
* 1) Generate the Δ terms.
gen dRDS = D.RDS
gen dHDD = D.HDD
gen dSNSR = D.SNSR
gen dprice = D.price_l3m

* 2) Estimate the full Unrestricted Error Model in the two subsamples. Store estimates.
qui reg dRDS L.RDS HDD SNSR price_l3m L(1/14).dRDS L(0/7).dHDD dSNSR dprice Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7 TimeTrend if sample_pre_crisis
estimates store pre

qui reg dRDS L.RDS HDD SNSR price_l3m L(1/8).dRDS L(0/7).dHDD dSNSR Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7 TimeTrend if sample_crisis
estimates store crisis

* Combine the estimates and test the two long-term coefficients as non-linear transformations of estimated parameters. 
suest pre crisis
testnl ([pre_mean]price_l3m/[pre_mean]L.RDS) = ([crisis_mean]price_l3m/[crisis_mean]L.RDS)

* Test the two long-term coefficients as non-linear transformations of estimated parameters. 
testnl ([pre_mean]HDD/[pre_mean]L.RDS) = ([crisis_mean]HDD/[crisis_mean]L.RDS)

* Test the two long-term coefficients as non-linear transformations of estimated parameters. 
testnl ([pre_mean]SNSR/[pre_mean]L.RDS) = ([crisis_mean]SNSR/[crisis_mean]L.RDS)

* Test the two long-term coefficients. 
test [pre_mean]L.RDS = [crisis_mean]L.RDS




************************* ELASTICITIES, SPLIT SAMPLES **************************

* Average yearly elasticities WITH 95% CIs.
preserve

* Create a variable to track years.
generate int year = year(Date)

* Initialize variables for elasticity and CIs.
gen eta_t = .
gen upper_eta = . 
gen lower_eta = .

* Generate an ID for the loops.
gen ID = 

* Compute yearly averages of consumption and price.
bysort year: egen mean_RDS = mean(RDS)

bysort year: egen mean_price_l3m = mean(price_l3m)

forvalues i = 3623(1)5114 {
	
	qui ardl RDS HDD SNSR price_l3m if sample_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) ec lags(9 8 1 0)

	qui scalar mean_price_t = mean_price_l3m[`i']
	
	qui scalar mean_RDS_t = mean_RDS[`i']
	
	qui lincom -[price_l3m * (mean_price_t / mean_RDS_t)]
	
	qui replace eta_t = r(estimate) if ID == `i'

	qui replace upper_eta = r(ub) if ID == `i'

	qui replace lower_eta = r(lb) if ID == `i'
		
}

drop ID

replace eta_t = 0 if missing(eta_t)
replace upper_eta = 0 if missing(upper_eta)
replace lower_eta = 0 if missing(lower_eta)

collapse (mean) eta_t upper_eta lower_eta, by(year)

tsset year, yearly 

twoway (tsline eta_t) (rcap lower_eta upper_eta year, lcolor(black)), xtick(2012(1)2024) xlabel(2012(1)2024) legend(rows(1) position(6) label(1 "Average Yearly Elasticity") label(2 "95% CI")) ytick(0(0.1)0.5) ylabel(0(0.1)0.5) xtitle("Date")
graph export RDS_Yearly_Elasticity_95_CI.png, as(png) replace 

restore




************************************ Q TILDE ***********************************

qui ardl RDS HDD SNSR price_l3m if sample_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) lags(9 8 1 0)

matrix coefficients = e(b)

gen b_RDS_L1 = coefficients[1,1]
gen b_RDS_L2 = coefficients[1,2]
gen b_RDS_L3 = coefficients[1,3]
gen b_RDS_L4 = coefficients[1,4]
gen b_RDS_L5 = coefficients[1,5]
gen b_RDS_L6 = coefficients[1,6]
gen b_RDS_L7 = coefficients[1,7]
gen b_RDS_L8 = coefficients[1,8]
gen b_RDS_L9 = coefficients[1,9]
gen b_HDD = coefficients[1,10]
gen b_HDD_L1 = coefficients[1,11]
gen b_HDD_L2 = coefficients[1,12]
gen b_HDD_L3 = coefficients[1,13]
gen b_HDD_L4 = coefficients[1,14]
gen b_HDD_L5 = coefficients[1,15]
gen b_HDD_L6 = coefficients[1,16]
gen b_HDD_L7 = coefficients[1,17]
gen b_HDD_L8 = coefficients[1,18]
gen b_SNSR = coefficients[1,19]
gen b_SNSR_L1 = coefficients[1,20]
gen b_Month_2 = coefficients[1,22]
gen b_Month_3 = coefficients[1,23]
gen b_Month_4 = coefficients[1,24]
gen b_Month_5 = coefficients[1,25]
gen b_Month_6 = coefficients[1,26]
gen b_Month_7 = coefficients[1,27]
gen b_Month_8 = coefficients[1,28]
gen b_Month_9 = coefficients[1,29]
gen b_Month_10 = coefficients[1,30]
gen b_Month_11 = coefficients[1,31]
gen b_Month_12 = coefficients[1,32]
gen b_Day_2 = coefficients[1,33]
gen b_Day_3 = coefficients[1,34]
gen b_Day_4 = coefficients[1,35]
gen b_Day_5 = coefficients[1,36]
gen b_Day_6 = coefficients[1,37]
gen b_Day_7 = coefficients[1,38]
gen b_TimeTrend = coefficients[1,39]

gen Q_tilde = max(RDS - (b_RDS_L1 * L1.RDS + b_RDS_L2 * L2.RDS + b_RDS_L3 * L3.RDS + b_RDS_L4 * L4.RDS + b_RDS_L5 * L5.RDS + ///
						b_RDS_L6 * L6.RDS + b_RDS_L7 * L7.RDS + b_RDS_L8 * L8.RDS + b_RDS_L9 * L9.RDS + ///
					    b_HDD * HDD + b_HDD_L1 * L1.HDD + b_HDD_L2 * L2.HDD + b_HDD_L3 * L3.HDD + b_HDD_L4 * L4.HDD + ///
					    b_HDD_L5 * L5.HDD + b_HDD_L6 * L6.HDD + b_HDD_L7 * L7.HDD + b_HDD_L8 * L8.HDD +  ///
					    b_SNSR * SNSR + b_SNSR_L1 * L1.SNSR + ///
					    b_Month_2 * Month_2 + b_Month_3 * Month_3 + b_Month_4 * Month_4 + b_Month_5 * Month_5 + b_Month_6 * Month_6 + ///
					    b_Month_7 * Month_7 + b_Month_8 * Month_8 + b_Month_9 * Month_9 + b_Month_10 * Month_10 + b_Month_11 * Month_11 + ///
					    b_Month_12 * Month_12 + b_Day_2 * Day_2 + b_Day_3 * Day_3 + b_Day_4 * Day_4 + b_Day_5 * Day_5 + b_Day_6 * Day_6 + ///
					    b_Day_7 * Day_7 + b_TimeTrend * TimeTrend), 0)

drop b_RDS_L1 b_RDS_L2 b_RDS_L3 b_RDS_L4 b_RDS_L5 b_RDS_L6 b_RDS_L7 b_RDS_L8 b_RDS_L9 b_HDD b_HDD_L1 b_HDD_L2 b_HDD_L3 b_HDD_L4 b_HDD_L5 b_HDD_L6 b_HDD_L7 b_HDD_L8 b_SNSR b_SNSR_L1 b_Month_2 b_Month_3 b_Month_4 b_Month_5 b_Month_6 b_Month_7 b_Month_8 b_Month_9 b_Month_10 b_Month_11 b_Month_12 b_Day_2 b_Day_3 b_Day_4 b_Day_5 b_Day_6 b_Day_7 b_TimeTrend

replace Q_tilde = 0 if Date < td("01/12/2021")



preserve

gen int mdate = mofd(Date)

format mdate %tm

collapse (sum) Q_tilde, by(mdate)

keep if mdate > tm(2012m1)

tsset mdate, monthly

tsline Q_tilde, ttick(2012m1 2014m1 2016m1 2018m1 2020m1 2022m1 2024m1 2026m1) tlabel(2012m1 "Jan 2012" 2014m1 "Jan 2014" 2016m1 "Jan 2016" 2018m1 "Jan 2018" 2020m1 "Jan 2020"  2022m1 "Jan 2022" 2024m1 "Jan 2024" 2026m1 "Jan 2026") xtitle("Date") ytitle("")
graph export Q_tilde.jpg, as(jpg) replace 

restore



* Compute and graph the average yearly elasticity with 95% CIs.
preserve

generate int year = year(Date)

* Initialize variables for elasticity and CIs.
gen eta_t_Q_tilde = .
gen upper_eta_Q_tilde = . 
gen lower_eta_Q_tilde = .

* Generate an ID for the loops.
gen ID = _n

bysort year: egen mean_Q_tilde = mean(Q_tilde)

bysort year: egen mean_price_l3m = mean(price_l3m)

forvalues i = 3623(1)5114 {
	
	qui ardl RDS HDD SNSR price_l3m if sample_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) ec lags(9 8 1 0)

	qui scalar mean_price_t = mean_price_l3m[`i']
	
	qui scalar mean_Q_tilde_t = mean_Q_tilde[`i']
	
	qui lincom -[price_l3m * (mean_price_t / mean_Q_tilde_t)]
	
	qui replace eta_t_Q_tilde = r(estimate) if ID == `i'

	qui replace upper_eta_Q_tilde = r(ub) if ID == `i'

	qui replace lower_eta_Q_tilde = r(lb) if ID == `i'
		
}

drop ID

replace eta_t_Q_tilde = 0 if missing(eta_t_Q_tilde)
replace upper_eta_Q_tilde = 0 if missing(upper_eta_Q_tilde)
replace lower_eta_Q_tilde = 0 if missing(lower_eta_Q_tilde)

collapse (mean) eta_t_Q_tilde lower_eta_Q_tilde upper_eta_Q_tilde, by(year)

tsset year, yearly 

twoway (tsline eta_t_Q_tilde) (rcap lower_eta_Q_tilde upper_eta_Q_tilde year, lcolor(black)), xtick(2012(1)2024) xlabel(2012(1)2024) legend(rows(1) position(6) label(1 "Average Yearly Elasticity") label(2 "95% CI")) ytick(0(0.5)2.5) ylabel(0(0.5)2.5)
graph export Q_tilde_Yearly_Elasticity_95_CI.jpg, as(jpg) replace 

restore




************************ REGRESSION: HEATING & BASELOAD ************************


* Model for Heating Consumption, PRE-CRISIS SAMPLE.
ardl heating HDD SNSR price_l3m if sample_pre_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) lags(15 8 1 1)
eststo model0

ardl heating HDD SNSR price_l3m if sample_pre_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) ec lags(15 8 1 1)
eststo model1

estat ectest

* Model for Heating Consumption, CRISIS SAMPLE.
ardl heating HDD SNSR price_l3m if sample_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) lags(9 8 1 0)
eststo model2

ardl heating HDD SNSR price_l3m if sample_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) ec lags(9 8 1 0)
eststo model3

estat ectest



* Model for Baseload Consumption, PRE-CRISIS SAMPLE.
ardl baseload HDD SNSR price_l3m if sample_pre_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) lags(19 0 0 0) 
eststo model4

ardl baseload HDD SNSR price_l3m if sample_pre_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) ec lags(19 0 0 0)
eststo model5

estat ectest

* Model for Baseload Consumption, CRISIS SAMPLE.
ardl baseload HDD SNSR price_l3m if sample_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) lags(11 0 0 0) 
eststo model6

ardl baseload HDD SNSR price_l3m if sample_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) ec lags(11 0 0 0)
eststo model7

estat ectest


esttab model0 model2 using "ARDL_Heat_DAILY.tex", replace b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) scalars(r2) label mtitle("Pre-Crisis Sample" "Crisis Sample") collabels(none) drop(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) varlabels(HDD "Heating‐Degree Days" SNSR "Solar Radiation" price_l3m "Lagged Price Index" _cons "Constant" date "Time Trend") compress sfmt(3 0) postfoot("\midrule" "Daily Seasonal Dummies & Yes & Yes \\ \\" "Monthly Seasonal Dummies & Yes & Yes\\")

esttab model4 model6 using "ARDL_Base_DAILY.tex", replace b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) scalars(r2) label mtitle("Pre-Crisis Sample" "Crisis Sample") collabels(none) drop(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) varlabels(HDD "Heating‐Degree Days" SNSR "Solar Radiation" price_l3m "Lagged Price Index" _cons "Constant" date "Time Trend") compress sfmt(3 0) postfoot("\midrule" "Daily Seasonal Dummies & Yes & Yes \\ \\" "Monthly Seasonal Dummies & Yes & Yes\\")


esttab model1 model3 using "ECM_Heating.tex", replace b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) scalars(r2) label mtitle("Pre-Crisis Sample" "Crisis Sample") collabels(none) drop(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) compress sfmt(3 0) postfoot("\midrule" "Daily Seasonal Dummies & Yes \\" "Monthly Seasonal Dummies & Yes\\")

esttab model5 model7 using "ECM_Baseload.tex", replace b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) scalars(r2) label mtitle("Baseload") collabels(none) drop(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) compress sfmt(3 0) postfoot("\midrule" "Daily Seasonal Dummies & Yes & Yes \\ \\" "Monthly Seasonal Dummies & Yes & Yes\\")


esttab model1 model3 using "ECM_Heating_TABLE.tex", replace b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) scalars(r2) label mtitle("Pre-Crisis" "Crisis") collabels(none) keep(HDD L.heating SNSR price_l3m) compress sfmt(3 0) varlabels(L.heating "Heating Demand" HDD "Heating‐Degree Days" SNSR "Solar Radiation" price_l3m "Lagged Price Index")

esttab model5 model7 using "ECM_Baseload_TABLE.tex", replace b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) scalars(r2) label mtitle("Pre-Crisis" "Crisis") collabels(none) keep(HDD L.baseload SNSR price_l3m) compress sfmt(3 0) varlabels(L.baseload "Baseload Demand" HDD "Heating‐Degree Days" SNSR "Solar Radiation" price_l3m "Lagged Price Index")




************************** TESTS: CRISIS vs PRE-CRISIS *************************

* Test whether the price coefficient estimated on the crisis subsample is different from the one estimated on the pre-crisis subsample: Wald test.
* 1) Generate the Δ terms.
gen dheating = D.heating
gen dbaseload = D.baseload


* 2) Estimate the full Unrestricted Error Model in the two subsamples. Store estimates.
qui reg dheating L.heating HDD SNSR price_l3m L(1/14).dheating L(0/7).dHDD dSNSR dprice Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7 TimeTrend if sample_pre_crisis
estimates store pre

qui reg dheating L.heating HDD SNSR price_l3m L(1/8).dheating L(0/7).dHDD dSNSR Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7 TimeTrend if sample_crisis
estimates store crisis

* Combine the estimates and test the two long-term coefficients as non-linear transformations of estimated parameters. 
qui suest pre crisis
* Test whether the price coefficient estimated on the crisis subsample is different from the one estimated on pre-crisis subsample: Wald test.
testnl ([pre_mean]price_l3m/[pre_mean]L.heating) = ([crisis_mean]price_l3m/[crisis_mean]L.heating)
* Test whether the HDD coefficient estimated on the crisis subsample is different from the one estimated on pre-crisis subsample: Wald test.
testnl ([pre_mean]HDD/[pre_mean]L.heating) = ([crisis_mean]HDD/[crisis_mean]L.heating)
* Test whether the SNSR coefficient estimated on the crisis subsample is different from the one estimated on pre-crisis subsample: Wald test.
testnl ([pre_mean]SNSR/[pre_mean]L.heating) = ([crisis_mean]SNSR/[crisis_mean]L.heating)



********************************* ELASTICITIES *********************************

* Yearly Average Elasticities.
* preserve

* qui ardl heating HDD SNSR price_l3m if sample_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) ec lags(9 8 1 0)

* matrix coefficients = e(b)

* gen β_heating = coefficients[1, 4]

* qui ardl baseload HDD SNSR price_l3m if sample_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) ec lags(11 0 0 0)

* matrix coefficients = e(b)

* gen β_baseload = coefficients[1, 4]

* qui ardl RDS HDD SNSR price_l3m if sample_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) ec lags(9 8 1 0)

* matrix coefficients = e(b)

* gen β_RDS = coefficients[1, 4]

* gen int ydate = yofd(Date)

* format ydate %tm

* collapse (mean) heating baseload price_l3m β_heating β_baseload β_RDS RDS, by(ydate)

* gen avg_ε_heating = abs(β_heating * price_l3m / heating)

* gen avg_ε_baseload = abs(β_baseload * price_l3m / baseload)

* gen avg_ε_RDS = abs(β_RDS * price_l3m / RDS)

* replace avg_ε_heating = 0 if ydate < 2022
* replace avg_ε_baseload = 0 if ydate < 2022
* replace avg_ε_RDS = 0 if ydate < 2022

* tsset ydate, yearly

* tsline avg_ε_RDS avg_ε_heating avg_ε_baseload, xtick(2012(1)2025) xlabel(2012(1)2025) xtitle(Date) ytitle("") name(elas_yearly_Heat_Base) legend(label(1 "Total Consumption") label(2 "Heating Consumption") label(3 "Baseload Consumption") rows(1))
* graph export Yearly_Elasticity_Base_Heat.jpg, as(jpg) replace 

* restore

* graph drop _all



* Average yearly elasticities WITH 95% CIs.
preserve

generate int year = year(Date)

* Initialize variables for elasticity and CIs.
gen eta_t_heat = .
gen upper_eta_heat = . 
gen lower_eta_heat = .
gen eta_t_base = .
gen upper_eta_base = . 
gen lower_eta_base = .

* Generate an ID for the loops.
gen ID = _n

bysort year: egen mean_heating = mean(heating)

bysort year: egen mean_baseload = mean(baseload)

bysort year: egen mean_price_l3m = mean(price_l3m)

forvalues i = 3623(1)5114 {
	
	qui ardl heating HDD SNSR price_l3m if sample_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) ec lags(9 8 1 0)

	qui scalar mean_price_t = mean_price_l3m[`i']
	
	qui scalar mean_heating_t = mean_heating[`i']
	
	qui lincom -[price_l3m * (mean_price_t / mean_heating_t)]
	
	qui replace eta_t_heat = r(estimate) if ID == `i'

	qui replace upper_eta_heat = r(ub) if ID == `i'

	qui replace lower_eta_heat = r(lb) if ID == `i'
		
}


forvalues i = 3623(1)5144 {
	
	qui ardl baseload HDD SNSR price_l3m if sample_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) ec lags(11 0 0 0)

	qui scalar mean_price_t = mean_price_l3m[`i']
	
	qui scalar mean_baseload_t = mean_baseload[`i']
	
	qui lincom -[price_l3m * (mean_price_t / mean_baseload_t)]
	
	qui replace eta_t_base = r(estimate) if ID == `i'

	qui replace upper_eta_base = r(ub) if ID == `i'

	qui replace lower_eta_base = r(lb) if ID == `i'
		
}

drop ID

replace eta_t_base = 0 if missing(eta_t_base)
replace upper_eta_base = 0 if missing(upper_eta_base)
replace lower_eta_base = 0 if missing(lower_eta_base)
replace eta_t_heat = 0 if missing(eta_t_heat)
replace upper_eta_heat = 0 if missing(upper_eta_heat)
replace lower_eta_heat = 0 if missing(lower_eta_heat)


collapse (mean) eta_t_heat eta_t_base upper_eta_heat upper_eta_base lower_eta_heat lower_eta_base, by(year)

tsset year, yearly 

twoway (tsline eta_t_heat) (rcap lower_eta_heat upper_eta_heat year, lcolor(black)) (tsline eta_t_base) (rcap lower_eta_base upper_eta_base year, lcolor(black)), ytick(0(0.1)0.8) ylabel(0(0.1)0.8) xtick(2012(1)2025) xlabel(2012(1)2025) legend(rows(1) position(6) order(1 3 2) label(1 "Avg. Yearly Elasticity (Heating)") label(3 "Avg. Yearly Elasticity (Baseload)") label(2 "95% CIs"))
graph export Base_Heat_Yearly_Elasticity_95_CI.png, as(png) replace 

restore

graph drop _all




***************************** PREDICTED CONSUMPTION ****************************

* Begin by running a model where we predict the coefficients on the historical data (i.e., before the crisis), and then use the estimated coefficients to predict consumption over the crisis. Then, use the Δ between actual and predicted consumption to measure savings.

ardl RDS HDD SNSR price_l3m if sample_pre_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) lags(15 8 1 1)

estimates store my_ardl_model

forecast create myforecast, replace
forecast estimates my_ardl_model
forecast solve, prefix(predicted_) begin(td("01/12/2021"))

preserve

keep if Date >= td("01/12/2021")

gen int mdate = mofd(Date)

format mdate %tm

collapse (sum) RDS predicted_RDS, by(mdate)

tsset mdate, monthly

gen savings = predicted_RDS - RDS

tsline RDS predicted_RDS, legend(row(1) pos(6) label(1 "Actual Consumption") label(2 "Predicted Consumption")) name(g1, replace) xtitle("") ytitle("")
graph export g1.png, as(png) replace 

tsline savings, ytick(-300(100)900) ylabel(-300(100)900) name(g2, replace) xtitle("") ytitle("")
graph export g2.png, as(png) replace

restore
graph drop _all


preserve

keep if Date >= td("01/12/2021")

gen year = year(Date)

gen savings = predicted_RDS - RDS

collapse (sum) savings, by(year)

restore


* Placebo test on the whole sample.
preserve

gen int mdate = mofd(Date)

format mdate %tm

collapse (sum) RDS predicted_RDS, by(mdate)

gen year = year(mdate)

tsset mdate

tsline RDS predicted_RDS if mdate < tm(2022m1), legend(row(1) pos(6) label(1 "Actual Consumption") label(2 "Predicted Consumption")) name(g1, replace) xtitle("") ytitle("")
graph export g3.png, as(png) replace

restore

graph drop _all
drop predicted_RDS

}




********************************************************************************
******************************** HDD, RDS, SNSSR *******************************
********************************************************************************

{

*********************************** CLEANING ***********************************

* Import the working database.
clear

*===============================================================================
* Complete with the file path to the daily data set.
*===============================================================================
import excel "", firstrow

*===============================================================================
* Set the working directory.
*===============================================================================
cd ""

* Rename the date variable for consistency with the code.
format date %tdDD/NN/CCYY
rename date Date

* Declare data to be time-series.
tsset Date, daily

* Label accordingly variables.
label variable Month_1 "January"
label variable Month_2 "February"
label variable Month_3 "March"
label variable Month_4 "April"
label variable Month_5 "May"
label variable Month_6 "June"
label variable Month_7 "July"
label variable Month_8 "August"
label variable Month_9 "September"
label variable Month_10 "October"
label variable Month_11 "November"
label variable Month_12 "December"

label variable Day_1 "Sunday"
label variable Day_2 "Monday"
label variable Day_3 "Tuesday"
label variable Day_4 "Wednesday"
label variable Day_5 "Thursday"
label variable Day_6 "Friday"
label variable Day_7 "Saturday"

label variable TimeTrend "Linear Time Trend"

label variable heating "Heating Consumption"
label variable baseload "Baseload Consumption"

* Initialize grouping variables that will be needed for the regressions to distinguish between the two different subsamples.
gen byte sample_pre_crisis = Date < td("01/12/2021")
gen byte sample_crisis = Date >= td("01/12/2021")



********************************* HDDs vs RDS **********************************

gen log_RDS = log(RDS)
*gen log_HDD = log(0.0000338817841215185/2 + HDD)
gen log_HDD = log(HDD)


label variable log_RDS "Log Demand"
label variable RDS "Demand"
label variable log_HDD "Log HDDs"
label variable HDD "HDDs"

qui reg RDS HDD
scalar r_squared_linear = round(e(r2), .0001)*100

qui reg log_RDS log_HDD
scalar r_squared_log = round(e(r2), .0001)*100

local rsq = "R² = " + string(r_squared_linear) + "%"

twoway (scatter RDS HDD) (lfit RDS HDD, ytitle("Demand (Millions of Sm³)") legend(off) text(100 16 "`rsq'") name(linear)) 

local rsq = "R² = " + string(r_squared_log) + "%"

twoway (scatter log_RDS log_HDD) (lfit log_RDS log_HDD, ytitle("Log Demand") legend(off) text(3.2 2.5 "`rsq'") name(log)) 

graph combine linear log, cols(2) iscale(1)
graph export HDD_RDS_Linear_Log.jpg, as(jpg) replace


********************************* HDDs vs SNSR *********************************

twoway (scatter HDD SNSR) (lfit HDD SNSR), title("") ytitle("HDD") xtitle("SNSR") ylabel(0(5)20) yscale(range(0 20)) xlabel(0(5)25) xscale(range(0 25)) legend(order(1 "Observed" 2 "Linear Fit") pos(6) row(1))
graph export HDD_vs_SNSR_scatter.jpg, as(jpg) replace 

graph drop _all

*********************************** CLEANING ***********************************

* Import the working database.
clear

*===============================================================================
* Complete with the file path to the daily data set.
*===============================================================================
import excel "",firstrow

*===============================================================================
* Set the working directory.
*===============================================================================
cd ""

* Declare data to be time-series.
tsset time, monthly

* Label accordingly variables.
label variable Month_1 "January"
label variable Month_2 "February"
label variable Month_3 "March"
label variable Month_4 "April"
label variable Month_5 "May"
label variable Month_6 "June"
label variable Month_7 "July"
label variable Month_8 "August"
label variable Month_9 "September"
label variable Month_10 "October"
label variable Month_11 "November"
label variable Month_12 "December"

label variable TimeTrend "Linear Time Trend"


* Initialize grouping variables that will be needed to graph over the different phases.
gen double date_num = daily(date, "DMY")

format date_num %tdDD/NN/CCYY

drop date

rename date_num Date


* Initialize grouping variables that will be needed to graph over the different phases.
gen group_1 = time < 744
gen group_2 = time > 743 & time < 754
gen group_3 = time > 753 & time < 764
gen group_4 = time > 763



************************************* HDDs *************************************
	
* Create the Monthly/Average Monthly graph for HDDs.
tsset time, monthly 

tsline HDD, tlabel(2012m1 "2012" 2014m1 "2014" 2016m1 "2016" 2018m1 "2018" 2020m1 "2020" 2022m1 "2022" 2024m1 "2024" 2026m1 "2026") ytitle("") xtitle("Date") ylabel(, format(%9.0f)) name(Monthly_HDD)

gen month = month(Date)

preserve

collapse (mean) HDD, by(month)

tsset month

tsline HDD, ytitle("") xtick(1 2 3 4 5 6 7 8 9 10 11 12) xlabel(1 2 3 4 5 6 7 8 9 10 11 12) xtitle("Month") ylabel(, format(%9.0f)) name(Average_Monthly_HDD)   

graph combine Monthly_HDD Average_Monthly_HDD, cols(2)
graph export HDD_Final.jpg, as(jpg) replace

graph drop _all

restore



************************************* SNSR *************************************

tsset time, monthly 

tsline SNSR, tlabel(2012m1 "2012" 2014m1 "2014" 2016m1 "2016" 2018m1 "2018" 2020m1 "2020" 2022m1 "2022" 2024m1 "2024" 2026m1 "2026") ytitle("") xtitle("Date") ylabel(, format(%9.0f)) name(Monthly_SNSR)

preserve

collapse (mean) SNSR, by(month)

tsset month

tsline SNSR, ytitle("") xtick(1 2 3 4 5 6 7 8 9 10 11 12) xlabel(1 2 3 4 5 6 7 8 9 10 11 12) xtitle("Month") ylabel(, format(%9.0f)) name(Average_Monthly_SNSR)   

graph combine Monthly_SNSR Average_Monthly_SNSR, cols(2)
graph export SNSR_Final.jpg, as(jpg) replace

graph drop _all

restore

drop month



************************************** RDS *************************************

tsset time, monthly 

tsline RDS, tlabel(2012m1 "2012" 2014m1 "2014" 2016m1 "2016" 2018m1 "2018" 2020m1 "2020" 2022m1 "2022" 2024m1 "2024" 2026m1 "2026") ytitle("") xtitle("Date") legend(off) tline(2022m2) ylabel(, format(%9.0f)) name(RDS) 
graph export RDS.jpg, as(jpg) replace


tsline price_l3m, tlabel(2012m1 "2012" 2014m1 "2014" 2016m1 "2016" 2018m1 "2018" 2020m1 "2020" 2022m1 "2022" 2024m1 "2024" 2026m1 "2026") ytitle("") xtitle("Date") legend(off) tline(2022m2) ylabel(, format(%9.0f)) name(Price) 
graph export Price.jpg, as(jpg) replace

graph drop _all



********************************* HDDs vs SNSR *********************************

forvalues i = 1(1)12{
	
	gen group_`i'_2022 = month(Date) == `i' & year(Date) == 2022
	
	gen group_`i'_2023 = month(Date) == `i' & year(Date) == 2023
	
	gen group_`i'_2024 = month(Date) == `i' & year(Date) == 2024
	
	gen group_`i'_2025 = month(Date) == `i' & year(Date) == 2025
	
}

* Replace with the values to graph.

forvalues i = 1(1)12{
	
	gen block`i'_HDD = HDD if Month_`i' == 1
	
	gen block`i'_SNSR = SNSR if Month_`i' == 1
	
	gen block`i'_2022_HDD = HDD if group_`i'_2022 == 1
	
	gen block`i'_2023_HDD = HDD if group_`i'_2023 == 1
	
	gen block`i'_2024_HDD = HDD if group_`i'_2024 == 1
	
	gen block`i'_2025_HDD = HDD if group_`i'_2025 == 1
	
	gen block`i'_2022_SNSR = SNSR if group_`i'_2022 == 1
	
	gen block`i'_2023_SNSR = SNSR if group_`i'_2023 == 1
	
	gen block`i'_2024_SNSR = SNSR if group_`i'_2024 == 1
	
	gen block`i'_2025_SNSR = SNSR if group_`i'_2025 == 1
	
}



twoway (scatter HDD SNSR, msize(0) connect(l) lcolor(black) lwidth(thin)) ///
	   (scatter block1_HDD block1_SNSR, mcolor(black) msymbol(O))  ///
	   (scatter block2_HDD block2_SNSR, mcolor(black) msymbol(D))  ///
	   (scatter block3_HDD block3_SNSR, mcolor(black) msymbol(T))  ///
	   (scatter block4_HDD block4_SNSR, mcolor(black) msymbol(S))  ///
	   (scatter block5_HDD block5_SNSR, mcolor(black) msymbol(+))  ///
	   (scatter block6_HDD block6_SNSR, mcolor(black) msymbol(X))  ///
	   (scatter block7_HDD block7_SNSR, mcolor(black) msymbol(A))  ///
	   (scatter block8_HDD block8_SNSR, mcolor(black) msymbol(|))  ///
	   (scatter block9_HDD block9_SNSR, mcolor(black) msymbol(V))  ///
	   (scatter block10_HDD block10_SNSR, mcolor(black) msymbol(th))  ///
	   (scatter block11_HDD block11_SNSR, mcolor(black) msymbol(oh))  ///
	   (scatter block12_HDD block12_SNSR, mcolor(black) msymbol(dh))  ///
	   (scatter block1_2022_HDD block1_2022_SNSR, mcolor(red) msymbol(O))  ///
	   (scatter block2_2022_HDD block2_2022_SNSR, mcolor(red) msymbol(D))  ///
	   (scatter block3_2022_HDD block3_2022_SNSR, mcolor(red) msymbol(T))  ///
	   (scatter block4_2022_HDD block4_2022_SNSR, mcolor(red) msymbol(S))  ///
	   (scatter block5_2022_HDD block5_2022_SNSR, mcolor(red) msymbol(+))  ///
	   (scatter block6_2022_HDD block6_2022_SNSR, mcolor(red) msymbol(X))  ///
	   (scatter block7_2022_HDD block7_2022_SNSR, mcolor(red) msymbol(A))  ///
	   (scatter block8_2022_HDD block8_2022_SNSR, mcolor(red) msymbol(|))  ///
	   (scatter block9_2022_HDD block9_2022_SNSR, mcolor(red) msymbol(V))  ///
	   (scatter block10_2022_HDD block10_2022_SNSR, mcolor(red) msymbol(th))  ///
	   (scatter block11_2022_HDD block11_2022_SNSR, mcolor(red) msymbol(oh))  ///
	   (scatter block12_2022_HDD block12_2022_SNSR, mcolor(red) msymbol(dh))  ///
	   (scatter block1_2023_HDD block1_2023_SNSR, mcolor(blue) msymbol(O))  ///
	   (scatter block2_2023_HDD block2_2023_SNSR, mcolor(blue) msymbol(D))  ///
	   (scatter block3_2023_HDD block3_2023_SNSR, mcolor(blue) msymbol(T))  ///
	   (scatter block4_2023_HDD block4_2023_SNSR, mcolor(blue) msymbol(S))  ///
	   (scatter block5_2023_HDD block5_2023_SNSR, mcolor(blue) msymbol(+))  ///
	   (scatter block6_2023_HDD block6_2023_SNSR, mcolor(blue) msymbol(X))  ///
	   (scatter block7_2023_HDD block7_2023_SNSR, mcolor(blue) msymbol(A))  ///
	   (scatter block8_2023_HDD block8_2023_SNSR, mcolor(blue) msymbol(|))  ///
	   (scatter block9_2023_HDD block9_2023_SNSR, mcolor(blue) msymbol(V))  ///
	   (scatter block10_2023_HDD block10_2023_SNSR, mcolor(blue) msymbol(th))  ///
	   (scatter block11_2023_HDD block11_2023_SNSR, mcolor(blue) msymbol(oh))  ///
	   (scatter block12_2023_HDD block12_2023_SNSR, mcolor(blue) msymbol(dh))  ///
	   (scatter block1_2024_HDD block1_2024_SNSR, mcolor(green) msymbol(O))  ///
	   (scatter block2_2024_HDD block2_2024_SNSR, mcolor(green) msymbol(D))  ///
	   (scatter block3_2024_HDD block3_2024_SNSR, mcolor(green) msymbol(T))  ///
	   (scatter block4_2024_HDD block4_2024_SNSR, mcolor(green) msymbol(S))  ///
	   (scatter block5_2024_HDD block5_2024_SNSR, mcolor(green) msymbol(+))  ///
	   (scatter block6_2024_HDD block6_2024_SNSR, mcolor(green) msymbol(X))  ///
	   (scatter block7_2024_HDD block7_2024_SNSR, mcolor(green) msymbol(A))  ///
	   (scatter block8_2024_HDD block8_2024_SNSR, mcolor(green) msymbol(|))  ///
	   (scatter block9_2024_HDD block9_2024_SNSR, mcolor(green) msymbol(V))  ///
	   (scatter block10_2024_HDD block10_2024_SNSR, mcolor(green) msymbol(th))  ///
	   (scatter block11_2024_HDD block11_2024_SNSR, mcolor(green) msymbol(oh))  ///
	   (scatter block12_2024_HDD block12_2024_SNSR, mcolor(green) msymbol(dh))  ///
	   (scatter block1_2025_HDD block1_2025_SNSR, mcolor(orange) msymbol(O))  ///
	   (scatter block2_2025_HDD block2_2025_SNSR, mcolor(orange) msymbol(D))  ///
	   (scatter block3_2025_HDD block3_2025_SNSR, mcolor(orange) msymbol(T))  ///
	   (scatter block4_2025_HDD block4_2025_SNSR, mcolor(orange) msymbol(S))  ///
	   (scatter block5_2025_HDD block5_2025_SNSR, mcolor(orange) msymbol(+))  ///
	   (scatter block6_2025_HDD block6_2025_SNSR, mcolor(orange) msymbol(X))  ///
	   (scatter block7_2025_HDD block7_2025_SNSR, mcolor(orange) msymbol(A))  ///
	   (scatter block8_2025_HDD block8_2025_SNSR, mcolor(orange) msymbol(|))  ///
	   (scatter block9_2025_HDD block9_2025_SNSR, mcolor(orange) msymbol(V))  ///
	   (scatter block10_2025_HDD block10_2025_SNSR, mcolor(orange) msymbol(th))  ///
	   (scatter block11_2025_HDD block11_2025_SNSR, mcolor(orange) msymbol(oh))  ///
	   (scatter block12_2025_HDD block12_2025_SNSR, mcolor(orange) msymbol(dh)),  ///	   
	   legend(position(6) rows(2) order(2 3 4 5 6 7 8 9 10 11 12 13 14 26 38 50) label(2 "January") label(3 "February") label(4 "March") label(5 "April") 		label(6 "May") label(7 "June") label(8 "July") label(9 "August") label(10 "September") label(11 "October") label(12 "November") label(13 "December") 	   label(14 "2022") label(26 "2023") label(38 "2024") label(50 "2025")) xtitle("SNSR") ytitle("HDD") ylabel(, format(%9.0f))
graph export HDD_vs_SNSR_by_Month.jpg, as(jpg) replace 

drop group_1_2022 group_1_2023 group_1_2024 group_2_2022 group_2_2023 group_2_2024 group_3_2022 group_3_2023 group_3_2024 group_4_2022 group_4_2023 group_4_2024 group_5_2022 group_5_2023 group_5_2024 group_6_2022 group_6_2023 group_6_2024 group_7_2022 group_7_2023 group_7_2024 group_8_2022 group_8_2023 group_8_2024 group_9_2022 group_9_2023 group_9_2024 group_10_2022 group_10_2023 group_10_2024 group_11_2022 group_11_2023 group_11_2024 group_12_2022 group_12_2023 group_12_2024 block1_HDD block1_SNSR block1_2022_HDD block1_2023_HDD block1_2024_HDD block1_2022_SNSR block1_2023_SNSR block1_2024_SNSR block2_HDD block2_SNSR block2_2022_HDD block2_2023_HDD block2_2024_HDD block2_2022_SNSR block2_2023_SNSR block2_2024_SNSR block3_HDD block3_SNSR block3_2022_HDD block3_2023_HDD block3_2024_HDD block3_2022_SNSR block3_2023_SNSR block3_2024_SNSR block4_HDD block4_SNSR block4_2022_HDD block4_2023_HDD block4_2024_HDD block4_2022_SNSR block4_2023_SNSR block4_2024_SNSR block5_HDD block5_SNSR block5_2022_HDD block5_2023_HDD block5_2024_HDD block5_2022_SNSR block5_2023_SNSR block5_2024_SNSR block6_HDD block6_SNSR block6_2022_HDD block6_2023_HDD block6_2024_HDD block6_2022_SNSR block6_2023_SNSR block6_2024_SNSR block7_HDD block7_SNSR block7_2022_HDD block7_2023_HDD block7_2024_HDD block7_2022_SNSR block7_2023_SNSR block7_2024_SNSR block8_HDD block8_SNSR block8_2022_HDD block8_2023_HDD block8_2024_HDD block8_2022_SNSR block8_2023_SNSR block8_2024_SNSR block9_HDD block9_SNSR block9_2022_HDD block9_2023_HDD block9_2024_HDD block9_2022_SNSR block9_2023_SNSR block9_2024_SNSR block10_HDD block10_SNSR block10_2022_HDD block10_2023_HDD block10_2024_HDD block10_2022_SNSR block10_2023_SNSR block10_2024_SNSR block11_HDD block11_SNSR block11_2022_HDD block11_2023_HDD block11_2024_HDD block11_2022_SNSR block11_2023_SNSR block11_2024_SNSR block12_HDD block12_SNSR block12_2022_HDD block12_2023_HDD block12_2024_HDD block12_2022_SNSR block12_2023_SNSR block12_2024_SNSR group_1_2025 group_2_2025 group_3_2025 group_4_2025 group_5_2025 group_6_2025 group_7_2025 group_8_2025 group_9_2025 group_10_2025 group_11_2025 group_12_2025 block1_2025_HDD block1_2025_SNSR block2_2025_HDD block2_2025_SNSR block3_2025_HDD block3_2025_SNSR block4_2025_HDD block4_2025_SNSR block5_2025_HDD block5_2025_SNSR block6_2025_HDD block6_2025_SNSR block7_2025_HDD block7_2025_SNSR block8_2025_HDD block8_2025_SNSR block9_2025_HDD block9_2025_SNSR block10_2025_HDD block10_2025_SNSR block11_2025_HDD block11_2025_SNSR block12_2025_HDD block12_2025_SNSR

graph drop _all

	
}




********************************************************************************
************************************* TESTS ************************************
********************************************************************************

{

*********************************** CLEANING ***********************************

* Import the working database.
clear
*===============================================================================
* Complete with the file path to the daily data set.
*===============================================================================
import excel "", firstrow

*===============================================================================
* Set the working directory.
*===============================================================================
cd ""

* Rename the date variable for consistency with the code.
format date %tdDD/NN/CCYY
rename date Date

* Declare data to be time-series.
tsset Date, daily

* Label accordingly variables.
label variable Month_1 "January"
label variable Month_2 "February"
label variable Month_3 "March"
label variable Month_4 "April"
label variable Month_5 "May"
label variable Month_6 "June"
label variable Month_7 "July"
label variable Month_8 "August"
label variable Month_9 "September"
label variable Month_10 "October"
label variable Month_11 "November"
label variable Month_12 "December"

label variable Day_1 "Sunday"
label variable Day_2 "Monday"
label variable Day_3 "Tuesday"
label variable Day_4 "Wednesday"
label variable Day_5 "Thursday"
label variable Day_6 "Friday"
label variable Day_7 "Saturday"

label variable TimeTrend "Linear Time Trend"

label variable heating "Heating Consumption"
label variable baseload "Baseload Consumption"

* Initialize grouping variables that will be needed for the regressions to distinguish between the two different subsamples.
gen byte sample_pre_crisis = Date < td("01/12/2021")
gen byte sample_crisis = Date >= td("01/12/2021")


************************************* TESTS ************************************

gen Δprice = D.price_l3m

* Define your variable list
local varlist "RDS HDD SNSR price_l3m Δprice"

* Open file for writing LaTeX table
file open latex_table using "unitroot_table.tex", write replace

* Write LaTeX table header
file write latex_table "\begin{table}[htbp]" _n
file write latex_table "\centering" _n
file write latex_table "\caption{Unit Root Test Results}" _n
file write latex_table "\label{tab:unitroot}" _n
file write latex_table "\begin{tabular}{lcccccc}" _n
file write latex_table "\toprule" _n
file write latex_table "Variable & ADF Stat & ADF p-val & PP Stat & PP p-val & KPSS Stat & KPSS p-val \\" _n
file write latex_table "\midrule" _n

* Loop through variables and write results
foreach var of local varlist {
    display "Processing variable: `var'"
    
    * Run ADF test (Augmented Dickey-Fuller)
    quietly dfuller `var', regress
    local adf_stat = string(r(Zt), "%8.3f")
    local adf_pval = string(r(p), "%6.3f")
    
    * Run Phillips-Perron test
    quietly pperron `var', regress
    local pp_stat = string(r(Zt), "%8.3f")
    local pp_pval = string(r(p), "%6.3f")
    
    * Run KPSS test
    quietly kpss `var'
    local kpss_stat = string(r(kpss10), "%8.3f")
    local kpss_pval = string(r(p10), "%6.3f")
    
    * Handle missing p-values (replace with "--" if missing)
    if "`adf_pval'" == "." local adf_pval "--"
    if "`pp_pval'" == "." local pp_pval "--"
    if "`kpss_pval'" == "." local kpss_pval "--"
    
    * Write row to table
    file write latex_table "`var' & `adf_stat' & `adf_pval' & `pp_stat' & `pp_pval' & `kpss_stat' & `kpss_pval' \\" _n
}

* Write table footer
file write latex_table "\bottomrule" _n
file write latex_table "\end{tabular}" _n
file write latex_table "\begin{tablenotes}" _n
file write latex_table "\footnotesize" _n
file write latex_table "\item Notes: ADF = Augmented Dickey-Fuller test; PP = Phillips-Perron test; KPSS = Kwiatkowski-Phillips-Schmidt-Shin test." _n
file write latex_table "\item Null hypothesis for ADF and PP: variable has a unit root (non-stationary)." _n
file write latex_table "\item Null hypothesis for KPSS: variable is stationary." _n
file write latex_table "\end{tablenotes}" _n
file write latex_table "\end{table}" _n

* Close the file
file close latex_table

* Display completion message
display "LaTeX table saved as 'unitroot_table.tex'"
display "Variables processed: `varlist'"




*===============================================================================
* ARDL Bounds Test Table - F-statistic and 1% Confidence Level Bounds
*===============================================================================

set more off

// Create the LaTeX table file
file open boundstable using "ardl_bounds_1pct.tex", write replace

// Write table header
file write boundstable "\begin{table}[htbp]" _n
file write boundstable "\centering" _n
file write boundstable "\caption{ARDL Bounds Test Results: F-statistic and 1\% Confidence Level Bounds}" _n
file write boundstable "\label{tab:ardl_bounds_1pct}" _n
file write boundstable "\begin{tabular}{lccc}" _n
file write boundstable "\toprule" _n
file write boundstable "Model & F-statistic & Lower Bound (1\%) & Upper Bound (1\%) \\" _n
file write boundstable "\midrule" _n

*===============================================================================
* Model 1: Demand (pre-crisis sample)
*===============================================================================
quietly ardl RDS HDD SNSR price_l3m if sample_pre_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) ec lags(15 8 1 1)
estat ectest

matrix bounds = r(cvmat)

local fstat_1 = string(e(F_pss), "%6.3f")
local lower_1 = string(bounds[1,5], "%5.2f")
local upper_1 = string(bounds[1,6], "%5.2f")

file write boundstable "Demand (pre-crisis sample) & `fstat_1' & `lower_1' & `upper_1' \\" _n

*===============================================================================
* Model 2: Demand (crisis sample)
*===============================================================================
quietly ardl RDS HDD SNSR price_l3m if sample_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) ec lags(9 8 1 0)
estat ectest

matrix bounds = r(cvmat)

local fstat_2 = string( e(F_pss), "%6.3f")
local lower_2 = string(bounds[1,5], "%5.2f")
local upper_2 = string(bounds[1,6], "%5.2f")

file write boundstable "Demand (crisis sample) & `fstat_2' & `lower_2' & `upper_2' \\" _n

*===============================================================================
* Model 3: Heating (pre-crisis sample)
*===============================================================================
quietly ardl heating HDD SNSR price_l3m if sample_pre_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) ec lags(15 8 1 1)
estat ectest

matrix bounds = r(cvmat)

local fstat_3 = string( e(F_pss), "%6.3f")
local lower_3 = string(bounds[1,5], "%5.2f")
local upper_3 = string(bounds[1,6], "%5.2f")

file write boundstable "Heating (pre-crisis sample) & `fstat_3' & `lower_3' & `upper_3' \\" _n

*===============================================================================
* Model 4: Heating (crisis sample)
*===============================================================================
quietly ardl heating HDD SNSR price_l3m if sample_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) ec lags(9 8 1 0)
estat ectest

matrix bounds = r(cvmat)

local fstat_4 = string( e(F_pss), "%6.3f")
local lower_4 = string(bounds[1,5], "%5.2f")
local upper_4 = string(bounds[1,6], "%5.2f")

file write boundstable "Heating (crisis sample) & `fstat_4' & `lower_4' & `upper_4' \\" _n

*===============================================================================
* Model 5: Baseload (pre-crisis sample)
*===============================================================================
quietly ardl baseload HDD SNSR price_l3m if sample_pre_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) ec lags(19 0 0 0)
estat ectest

matrix bounds = r(cvmat)

local fstat_5 = string( e(F_pss), "%6.3f")
local lower_5 = string(bounds[1,5], "%5.2f")
local upper_5 = string(bounds[1,6], "%5.2f")

file write boundstable "Baseload (pre-crisis sample) & `fstat_5' & `lower_5' & `upper_5' \\" _n

*===============================================================================
* Model 6: Baseload (crisis sample)
*===============================================================================
quietly ardl baseload HDD SNSR price_l3m if sample_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) ec lags(11 0 0 0)
estat ectest

matrix bounds = r(cvmat)

local fstat_6 = string( e(F_pss), "%6.3f")
local lower_6 = string(bounds[1,5], "%5.2f")
local upper_6 = string(bounds[1,6], "%5.2f")

file write boundstable "Baseload (crisis sample) & `fstat_6' & `lower_6' & `upper_6' \\" _n

*===============================================================================
* Close table and add notes
*===============================================================================
file write boundstable "\bottomrule" _n
file write boundstable "\end{tabular}" _n
file write boundstable "\begin{tablenotes}" _n
file write boundstable "\small" _n
file write boundstable "\item \textbf{Notes:} This table reports the computed F-statistic and the most extreme bounds for the F-statistic at the 1\% confidence level. " _n
file write boundstable "The bounds test evaluates the null hypothesis of no cointegration among the variables. " _n
file write boundstable "Critical values at the 1\% level represent the most stringent test for cointegration." _n
file write boundstable "\end{tablenotes}" _n
file write boundstable "\end{table}" _n

// Close file
file close boundstable



*===============================================================================
* BAI-PERRON TEST AT MONTHLY RESOLUTION
*===============================================================================

* Import the working database.

clear

*===============================================================================
* Complete with the file path to the monthly data set.
*===============================================================================
import excel "",firstrow

*===============================================================================
* Set the working directory.
*===============================================================================
cd ""


* Declare data to be time-series.
tsset time, monthly

* Label accordingly variables.
label variable Month_1 "January"
label variable Month_2 "February"
label variable Month_3 "March"
label variable Month_4 "April"
label variable Month_5 "May"
label variable Month_6 "June"
label variable Month_7 "July"
label variable Month_8 "August"
label variable Month_9 "September"
label variable Month_10 "October"
label variable Month_11 "November"
label variable Month_12 "December"

label variable TimeTrend "Linear Time Trend"


gen double date_num = daily(date, "DMY")

format date_num %tdDD/NN/CCYY

drop date

rename date_num Date 

* ardl RDS HDD SNSR price_l3m, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12) maxlags(10)
ardl RDS HDD SNSR price_l3m, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12) lags(2 1 0 1)
ardl RDS HDD SNSR price_l3m, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12) ec lags(2 1 0 1)
estat ectest

gen dRDS = D.RDS
gen dHDD = D.HDD
gen dprice_l3m = D.price_l3m

xtbreak test dRDS L.RDS HDD SNSR price_l3m L.dRDS dHDD dprice Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 TimeTrend, breaks(1) h(1)


}




********************************************************************************
******************************* ROBUSTNESS CHECKS ******************************
********************************************************************************

{

*------------------------------------------------------------------------------*
*-------------------------------- CHECK NO SNSR -------------------------------*
*------------------------------------------------------------------------------*

{

*********************************** CLEANING ***********************************

* Import the working database.
clear
*===============================================================================
* Complete with the file path to the daily data set.
*===============================================================================
import excel "", firstrow

*===============================================================================
* Set the working directory.
*===============================================================================
cd ""

* Rename the date variable for consistency with the code.
format date %tdDD/NN/CCYY
rename date Date

* Declare data to be time-series.
tsset Date, daily

* Label accordingly variables.
label variable Month_1 "January"
label variable Month_2 "February"
label variable Month_3 "March"
label variable Month_4 "April"
label variable Month_5 "May"
label variable Month_6 "June"
label variable Month_7 "July"
label variable Month_8 "August"
label variable Month_9 "September"
label variable Month_10 "October"
label variable Month_11 "November"
label variable Month_12 "December"

label variable Day_1 "Sunday"
label variable Day_2 "Monday"
label variable Day_3 "Tuesday"
label variable Day_4 "Wednesday"
label variable Day_5 "Thursday"
label variable Day_6 "Friday"
label variable Day_7 "Saturday"

label variable TimeTrend "Linear Time Trend"

label variable heating "Heating Consumption"
label variable baseload "Baseload Consumption"

* Initialize grouping variables that will be needed for the regressions to distinguish between the two different subsamples.
gen byte sample_pre_crisis = Date < td("01/12/2021")
gen byte sample_crisis = Date >= td("01/12/2021")




************************* REGRESSION: TOTAL CONSUMPTION ************************

* Model for Total Consumption, pre-crisis sample.
* ARDL.
ardl RDS HDD price_l3m if sample_pre_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) lags(9 8 1)

* ECM.
ardl RDS HDD price_l3m if sample_pre_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) ec lags(9 8 1)



* Model for Total Consumption, crisis sample.
* ARDL.
ardl RDS HDD price_l3m if sample_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) lags(9 8 0)

* ECM.
ardl RDS HDD price_l3m if sample_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) ec lags(9 8 0)




************************* ELASTICITIES, SPLIT SAMPLES **************************

* Average yearly elasticities WITH 95% CIs.
preserve

* Create a variable to track years.
generate int year = year(Date)

* Initialize variables for elasticity and CIs.
gen eta_t = .
gen upper_eta = . 
gen lower_eta = .

* Generate an ID for the loops.
gen ID = _n

* Compute yearly averages of consumption and price.
bysort year: egen mean_RDS = mean(RDS)

bysort year: egen mean_price_l3m = mean(price_l3m)

forvalues i = 3623(1)5114 {
	
	qui ardl RDS HDD price_l3m if sample_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) ec maxlags(20) lags(9 8 0)

	qui scalar mean_price_t = mean_price_l3m[`i']
	
	qui scalar mean_RDS_t = mean_RDS[`i']
	
	qui lincom -[price_l3m * (mean_price_t / mean_RDS_t)]
	
	qui replace eta_t = r(estimate) if ID == `i'

	qui replace upper_eta = r(ub) if ID == `i'

	qui replace lower_eta = r(lb) if ID == `i'
		
}

drop ID

replace eta_t = 0 if missing(eta_t)
replace upper_eta = 0 if missing(upper_eta)
replace lower_eta = 0 if missing(lower_eta)

collapse (mean) eta_t upper_eta lower_eta, by(year)

tsset year, yearly

twoway (tsline eta_t) (rcap lower_eta upper_eta year, lcolor(black)), xtick(2012(1)2024) xlabel(2012(1)2024) legend(rows(1) position(6) label(1 "Average Yearly Elasticity") label(2 "95% CI")) ytick(0(0.1)0.5) ylabel(0(0.1)0.5) xtitle("Date")
graph export RDS_Yearly_Elasticity_95_CI.png, as(png) replace 

restore




************************************ Q TILDE ***********************************

qui ardl RDS HDD price_l3m if sample_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) lags(9 8 0)

matrix coefficients = e(b)

gen b_RDS_L1 = coefficients[1,1]
gen b_RDS_L2 = coefficients[1,2]
gen b_RDS_L3 = coefficients[1,3]
gen b_RDS_L4 = coefficients[1,4]
gen b_RDS_L5 = coefficients[1,5]
gen b_RDS_L6 = coefficients[1,6]
gen b_RDS_L7 = coefficients[1,7]
gen b_RDS_L8 = coefficients[1,8]
gen b_RDS_L9 = coefficients[1,9]
gen b_HDD = coefficients[1,10]
gen b_HDD_L1 = coefficients[1,11]
gen b_HDD_L2 = coefficients[1,12]
gen b_HDD_L3 = coefficients[1,13]
gen b_HDD_L4 = coefficients[1,14]
gen b_HDD_L5 = coefficients[1,15]
gen b_HDD_L6 = coefficients[1,16]
gen b_HDD_L7 = coefficients[1,17]
gen b_HDD_L8 = coefficients[1,18]
gen b_Month_2 = coefficients[1,20]
gen b_Month_3 = coefficients[1,21]
gen b_Month_4 = coefficients[1,22]
gen b_Month_5 = coefficients[1,23]
gen b_Month_6 = coefficients[1,24]
gen b_Month_7 = coefficients[1,25]
gen b_Month_8 = coefficients[1,26]
gen b_Month_9 = coefficients[1,27]
gen b_Month_10 = coefficients[1,28]
gen b_Month_11 = coefficients[1,29]
gen b_Month_12 = coefficients[1,30]
gen b_Day_2 = coefficients[1,31]
gen b_Day_3 = coefficients[1,32]
gen b_Day_4 = coefficients[1,33]
gen b_Day_5 = coefficients[1,34]
gen b_Day_6 = coefficients[1,35]
gen b_Day_7 = coefficients[1,36]
gen b_TimeTrend = coefficients[1,37]

gen Q_tilde= max(RDS - (b_RDS_L1 * L1.RDS + b_RDS_L2 * L2.RDS + b_RDS_L3 * L3.RDS + b_RDS_L4 * L4.RDS + b_RDS_L5 * L5.RDS + ///
						b_RDS_L6 * L6.RDS + b_RDS_L7 * L7.RDS + b_RDS_L8 * L8.RDS + b_RDS_L9 * L9.RDS + ///
					    b_HDD * HDD + b_HDD_L1 * L1.HDD + b_HDD_L2 * L2.HDD + b_HDD_L3 * L3.HDD + b_HDD_L4 * L4.HDD + ///
					    b_HDD_L5 * L5.HDD + b_HDD_L6 * L6.HDD + b_HDD_L7 * L7.HDD + b_HDD_L8 * L8.HDD + ///
					    b_Month_2 * Month_2 + b_Month_3 * Month_3 + b_Month_4 * Month_4 + b_Month_5 * Month_5 + b_Month_6 * Month_6 + ///
					    b_Month_7 * Month_7 + b_Month_8 * Month_8 + b_Month_9 * Month_9 + b_Month_10 * Month_10 + b_Month_11 * Month_11 + ///
					    b_Month_12 * Month_12 + b_Day_2 * Day_2 + b_Day_3 * Day_3 + b_Day_4 * Day_4 + b_Day_5 * Day_5 + b_Day_6 * Day_6 + ///
					    b_Day_7 * Day_7 + b_TimeTrend * TimeTrend), 0)
									
drop b_RDS_L1 b_RDS_L2 b_RDS_L3 b_RDS_L4 b_RDS_L5 b_RDS_L6 b_RDS_L7 b_RDS_L8 b_RDS_L9 b_HDD b_HDD_L1 b_HDD_L2 b_HDD_L3 b_HDD_L4 b_HDD_L5 b_HDD_L6 b_HDD_L7 b_HDD_L8 b_Month_2 b_Month_3 b_Month_4 b_Month_5 b_Month_6 b_Month_7 b_Month_8 b_Month_9 b_Month_10 b_Month_11 b_Month_12 b_Day_2 b_Day_3 b_Day_4 b_Day_5 b_Day_6 b_Day_7 b_TimeTrend

replace Q_tilde = 0 if Date < td("01/12/2021")



preserve

gen int mdate = mofd(Date)

format mdate %tm

collapse (sum) Q_tilde, by(mdate)

keep if mdate > tm(2012m1)

tsset mdate, monthly

tsline Q_tilde, ttick(2012m1 2014m1 2016m1 2018m1 2020m1 2022m1 2024m1 2026m1) tlabel(2012m1 "Jan 2012" 2014m1 "Jan 2014" 2016m1 "Jan 2016" 2018m1 "Jan 2018" 2020m1 "Jan 2020"  2022m1 "Jan 2022" 2024m1 "Jan 2024" 2026m1 "Jan 2026") xtitle("Date") ytitle("")
graph export Q_tilde.jpg, as(jpg) replace 

restore



* Compute and graph the average yearly elasticity with 95% CIs.
preserve

generate int year = year(Date)

* Initialize variables for elasticity and CIs.
gen eta_t_Q_tilde = .
gen upper_eta_Q_tilde = . 
gen lower_eta_Q_tilde = .

* Generate an ID for the loops.
gen ID = _n

bysort year: egen mean_Q_tilde = mean(Q_tilde)

bysort year: egen mean_price_l3m = mean(price_l3m)

forvalues i = 3623(1)5114 {
	
	qui ardl RDS HDD price_l3m if sample_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) ec lags(9 8 0)

	qui scalar mean_price_t = mean_price_l3m[`i']
	
	qui scalar mean_Q_tilde_t = mean_Q_tilde[`i']
	
	qui lincom -[price_l3m * (mean_price_t / mean_Q_tilde_t)]
	
	qui replace eta_t_Q_tilde = r(estimate) if ID == `i'

	qui replace upper_eta_Q_tilde = r(ub) if ID == `i'

	qui replace lower_eta_Q_tilde = r(lb) if ID == `i'
		
}

drop ID

replace eta_t_Q_tilde = 0 if missing(eta_t_Q_tilde)
replace upper_eta_Q_tilde = 0 if missing(upper_eta_Q_tilde)
replace lower_eta_Q_tilde = 0 if missing(lower_eta_Q_tilde)

collapse (mean) eta_t_Q_tilde lower_eta_Q_tilde upper_eta_Q_tilde, by(year)

tsset year, yearly 

twoway (tsline eta_t_Q_tilde) (rcap lower_eta_Q_tilde upper_eta_Q_tilde year, lcolor(black)), xtick(2012(1)2024) xlabel(2012(1)2024) legend(rows(1) position(6) label(1 "Average Yearly Elasticity") label(2 "95% CI")) ytick(0(0.5)2.5) ylabel(0(0.5)2.5)
graph export Q_tilde_Yearly_Elasticity_95_CI.jpg, as(jpg) replace 

restore




************************ REGRESSION: HEATING & BASELOAD ************************


* Model for Heating Consumption, PRE-CRISIS SAMPLE.
ardl heating HDD price_l3m if sample_pre_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) lags(9 8 1)
eststo model0

ardl heating HDD price_l3m if sample_pre_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) ec lags(9 8 1)
eststo model1

estat ectest

* Model for Heating Consumption, CRISIS SAMPLE.
ardl heating HDD price_l3m if sample_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) lags(9 8 0)
eststo model2

ardl heating HDD price_l3m if sample_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) ec lags(9 8 0)
eststo model3

estat ectest



* Model for Baseload Consumption, PRE-CRISIS SAMPLE.
ardl baseload HDD price_l3m if sample_pre_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) lags(19 0 0) 

ardl baseload HDD price_l3m if sample_pre_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) ec lags(19 0 0)

* Model for Baseload Consumption, CRISIS SAMPLE.
ardl baseload HDD price_l3m if sample_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) lags(11 0 0) 

ardl baseload HDD price_l3m if sample_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) ec lags(11 0 0)



********************************* ELASTICITIES *********************************

* Yearly Average Elasticities.
preserve

qui ardl heating HDD price_l3m if sample_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) ec lags(9 8 0)

matrix coefficients = e(b)

gen β_heating = coefficients[1, 4]

qui ardl baseload HDD price_l3m if sample_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) ec lags(11 0 0)

matrix coefficients = e(b)

gen β_baseload = coefficients[1, 4]

qui ardl RDS HDD price_l3m if sample_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) ec lags(9 8 0)

matrix coefficients = e(b)

gen β_RDS = coefficients[1, 4]

gen int ydate = yofd(Date)

format ydate %tm

collapse (mean) heating baseload price_l3m β_heating β_baseload β_RDS RDS, by(ydate)

gen avg_ε_heating = abs(β_heating * price_l3m / heating)

gen avg_ε_baseload = abs(β_baseload * price_l3m / baseload)

gen avg_ε_RDS = abs(β_RDS * price_l3m / RDS)


tsset ydate, yearly

tsline avg_ε_RDS avg_ε_heating avg_ε_baseload, xtick(2012(1)2025) xlabel(2012(1)2025) xtitle(Date) ytitle("") name(elas_yearly_Heat_Base) legend(label(1 "Total Consumption") label(2 "Heating Consumption") label(3 "Baseload Consumption") rows(1))
graph export Yearly_Elasticity_Base_Heat.jpg, as(jpg) replace 

restore

graph drop _all



* Average yearly elasticities WITH 95% CIs.
preserve

generate int year = year(Date)

* Initialize variables for elasticity and CIs.
gen eta_t_heat = .
gen upper_eta_heat = . 
gen lower_eta_heat = .
gen eta_t_base = .
gen upper_eta_base = . 
gen lower_eta_base = .

* Generate an ID for the loops.
gen ID = _n

bysort year: egen mean_heating = mean(heating)

bysort year: egen mean_baseload = mean(baseload)

bysort year: egen mean_price_l3m = mean(price_l3m)

forvalues i = 3623(1)5114 {
	
	qui ardl heating HDD price_l3m if sample_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) ec lags(9 8 0)

	qui scalar mean_price_t = mean_price_l3m[`i']
	
	qui scalar mean_heating_t = mean_heating[`i']
	
	qui lincom -[price_l3m * (mean_price_t / mean_heating_t)]
	
	qui replace eta_t_heat = r(estimate) if ID == `i'

	qui replace upper_eta_heat = r(ub) if ID == `i'

	qui replace lower_eta_heat = r(lb) if ID == `i'
		
}


forvalues i = 3623(1)5144 {
	
	qui ardl baseload HDD price_l3m if sample_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) ec lags(11 0 0)

	qui scalar mean_price_t = mean_price_l3m[`i']
	
	qui scalar mean_baseload_t = mean_baseload[`i']
	
	qui lincom -[price_l3m * (mean_price_t / mean_baseload_t)]
	
	qui replace eta_t_base = r(estimate) if ID == `i'

	qui replace upper_eta_base = r(ub) if ID == `i'

	qui replace lower_eta_base = r(lb) if ID == `i'
		
}

drop ID

replace eta_t_base = 0 if missing(eta_t_base)
replace upper_eta_base = 0 if missing(upper_eta_base)
replace lower_eta_base = 0 if missing(lower_eta_base)
replace eta_t_heat = 0 if missing(eta_t_heat)
replace upper_eta_heat = 0 if missing(upper_eta_heat)
replace lower_eta_heat = 0 if missing(lower_eta_heat)


collapse (mean) eta_t_heat eta_t_base upper_eta_heat upper_eta_base lower_eta_heat lower_eta_base, by(year)

tsset year, yearly 

twoway (tsline eta_t_heat) (rcap lower_eta_heat upper_eta_heat year, lcolor(black)) (tsline eta_t_base) (rcap lower_eta_base upper_eta_base year, lcolor(black)), ytick(0(0.1)0.8) ylabel(0(0.1)0.8) xtick(2012(1)2025) xlabel(2012(1)2025) legend(rows(1) position(6) order(1 3 2) label(1 "Avg. Yearly Elasticity (Heating)") label(3 "Avg. Yearly Elasticity (Baseload)") label(2 "95% CIs"))
graph export Base_Heat_Yearly_Elasticity_95_CI.png, as(png) replace 

restore

graph drop _all




***************************** PREDICTED CONSUMPTION ****************************

* Begin by running a model where we predict the coefficients on the historical data (i.e., before the crisis), and then use the estimated coefficients to predict consumption over the crisis. Then, use the Δ between actual and predicted consumption to measure savings.

ardl RDS HDD price_l3m if sample_pre_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) lags(9 8 0)

estimates store my_ardl_model

forecast create myforecast, replace
forecast estimates my_ardl_model
forecast solve, prefix(predicted_) begin(td("01/12/2021"))

preserve

keep if Date >= td("01/12/2021")

gen int mdate = mofd(Date)

gen year = year(Date)

format mdate %tm

collapse (sum) RDS predicted_RDS, by(mdate)

tsset mdate, monthly

gen savings = predicted_RDS - RDS

tsline RDS predicted_RDS, legend(row(1) pos(6) label(1 "Actual Consumption") label(2 "Predicted Consumption")) name(g1, replace) xtitle("") ytitle("")
graph export g1.png, as(png) replace 

tsline savings, ytick(-300(100)900) ylabel(-300(100)900) name(g2, replace) xtitle("") ytitle("")
graph export g2.png, as(png) replace

restore


graph drop _all



* Placebo test on the whole sample.
preserve

gen int mdate = mofd(Date)

format mdate %tm

collapse (sum) RDS predicted_RDS, by(mdate)

tsset mdate

tsline RDS predicted_RDS, legend(row(1) pos(6) label(1 "Actual Consumption") label(2 "Predicted Consumption")) name(g1, replace) xtitle("") ytitle("")

restore

graph drop _all
drop predicted_RDS

}


*------------------------------------------------------------------------------*
*--------------------------- GOVERNMENT INTERVENTION --------------------------*
*------------------------------------------------------------------------------*

{

*********************************** CLEANING ***********************************

* Import the working database.
clear

import excel "", firstrow

* Set the WD.
cd ""

* Rename the date variable for consistency with the code.
format date %tdDD/NN/CCYY
rename date Date

* Declare data to be time-series.
tsset Date, daily

* Label accordingly variables.
label variable Month_1 "January"
label variable Month_2 "February"
label variable Month_3 "March"
label variable Month_4 "April"
label variable Month_5 "May"
label variable Month_6 "June"
label variable Month_7 "July"
label variable Month_8 "August"
label variable Month_9 "September"
label variable Month_10 "October"
label variable Month_11 "November"
label variable Month_12 "December"

label variable Day_1 "Sunday"
label variable Day_2 "Monday"
label variable Day_3 "Tuesday"
label variable Day_4 "Wednesday"
label variable Day_5 "Thursday"
label variable Day_6 "Friday"
label variable Day_7 "Saturday"

label variable TimeTrend "Linear Time Trend"

label variable heating "Heating Consumption"
label variable baseload "Baseload Consumption"

* Initialize grouping variables that will be needed for the regressions to distinguish between the two different subsamples.
gen byte sample_pre_crisis = Date < td("01/12/2021")
gen byte sample_crisis = Date >= td("01/12/2021")

* Initialize grouping variables to identify the periods of government intervention. 
gen byte government_cut_oct = Date >= td("15/10/2022") & Date <= td("21/10/2022")
gen byte government_cut_apr = Date >= td("07/04/2023") & Date <= td("14/04/2023")
gen government_cut = government_cut_oct + government_cut_apr
gen byte government_cap = Date >= td("22/10/2022") & Date <= td("06/04/2023")

drop government_cut_oct government_cut_apr



************************* REGRESSION: TOTAL CONSUMPTION ************************
* Model for Total Consumption, crisis sample.
ardl RDS HDD SNSR price_l3m if sample_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) ec lags(9 8 1 0)
matrix lr1 = e(b)
scalar price_lr1 = lr1[1,4]

* Models for Total Consumption, crisis sample WITH GOVERNMENT INTERVENTION
* Model with only the cut.
ardl RDS HDD SNSR price_l3m if sample_crisis, bic trendvar exog(government_cut Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7 ) ec lags(9 8 1 0)
matrix lr2 = e(b)
scalar price_lr2 = lr2[1,4]

* Model with only the cap.
ardl RDS HDD SNSR price_l3m if sample_crisis, bic trendvar exog(government_cap Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7 ) ec lags(9 8 1 0)
matrix lr3 = e(b)
scalar price_lr3 = lr3[1,4]

* Model with both the cap and the cut.
ardl RDS HDD SNSR price_l3m if sample_crisis, bic trendvar exog(government_cut government_cap Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7 ) ec lags(9 8 1 0)
matrix lr4 = e(b)
scalar price_lr4 = lr4[1,4]


* Display results
display _newline "Long-Run Coefficients on price_l3m:"
display _newline "Model 1 (Baseline):      " %9.4f price_lr1 "
display "Model 2 (Government CAP only): " %9.4f price_lr2
display "Model 3 (Government CUT only): " %9.4f price_lr3
display "Model 4 (Government CAP and CUT): " %9.4f price_lr4



************************* ELASTICITIES, SPLIT SAMPLES **************************

preserve

* Create a variable to track years.
generate int year = year(Date)

* Initialize variables for elasticity and CIs.
gen eta_t = .
gen upper_eta = . 
gen lower_eta = .
gen eta_t_gov = .
gen upper_eta_gov = . 
gen lower_eta_gov = .

* Generate an ID for the loops.
gen ID = _n

* Compute yearly averages of consumption and price.
bysort year: egen mean_RDS = mean(RDS)

bysort year: egen mean_price_l3m = mean(price_l3m)

forvalues i = 3623(1)5114 {
	
	qui ardl RDS HDD SNSR price_l3m if sample_crisis, bic trendvar exog(government_cut government_cap Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7 ) ec lags(9 8 1 0)

	qui scalar mean_price_t = mean_price_l3m[`i']
	
	qui scalar mean_RDS_t = mean_RDS[`i']
	
	qui lincom -[price_l3m * (mean_price_t / mean_RDS_t)]
	
	qui replace eta_t_gov = r(estimate) if ID == `i'

	qui replace upper_eta_gov = r(ub) if ID == `i'

	qui replace lower_eta_gov = r(lb) if ID == `i'
		
}


forvalues i = 3623(1)5114 {
	
	qui ardl RDS HDD SNSR price_l3m if sample_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7 ) ec lags(9 8 1 0)

	qui scalar mean_price_t = mean_price_l3m[`i']
	
	qui scalar mean_RDS_t = mean_RDS[`i']
	
	qui lincom -[price_l3m * (mean_price_t / mean_RDS_t)]
	
	qui replace eta_t = r(estimate) if ID == `i'

	qui replace upper_eta = r(ub) if ID == `i'

	qui replace lower_eta = r(lb) if ID == `i'
		
}


replace eta_t_gov = 0 if missing(eta_t_gov)
replace upper_eta_gov = 0 if missing(upper_eta_gov)
replace lower_eta_gov = 0 if missing(lower_eta_gov)
replace eta_t = 0 if missing(eta_t)
replace upper_eta = 0 if missing(upper_eta)
replace lower_eta = 0 if missing(lower_eta)



drop ID
collapse (mean) eta_t upper_eta lower_eta eta_t_gov upper_eta_gov lower_eta_gov, by(year)

tsset year, yearly 

twoway (tsline eta_t) (rcap lower_eta upper_eta year, lcolor(black)), xtick(2012(1)2025) xlabel(2012(1)2025) legend(rows(1) position(6) label(1 "Avg. Yearly Elasticity (Baseline Model)") label(2 "95% CI")) ytick(0(0.1)0.5) ylabel(0(0.1)0.5) xtitle("") name(g1, replace)

twoway (tsline eta_t_gov) (rcap lower_eta_gov upper_eta_gov year, lcolor(black)), xtick(2012(1)2025) xlabel(2012(1)2025) legend(rows(1) position(6) label(1 "Avg. Yearly Elasticity (Full set of Gov. Intervention Dummies)") label(2 "95% CI")) ytick(0(0.1)0.5) ylabel(0(0.1)0.5) xtitle("Date") name(g2, replace)

graph combine g1 g2, cols(1)
graph export RDS_Yearly_Elasticity_Gov.png, as(png) replace

restore

graph drop _all

}


*------------------------------------------------------------------------------*
*---------------------------------- NO COVID ----------------------------------*
*------------------------------------------------------------------------------*

{
	
*********************************** CLEANING ***********************************

* Import the working database.
clear

import excel "", firstrow

* Set the WD.
cd ""

* Rename the date variable for consistency with the code.
format date %tdDD/NN/CCYY
rename date Date

* Declare data to be time-series.
tsset Date, daily

* Label accordingly variables.
label variable Month_1 "January"
label variable Month_2 "February"
label variable Month_3 "March"
label variable Month_4 "April"
label variable Month_5 "May"
label variable Month_6 "June"
label variable Month_7 "July"
label variable Month_8 "August"
label variable Month_9 "September"
label variable Month_10 "October"
label variable Month_11 "November"
label variable Month_12 "December"

label variable Day_1 "Sunday"
label variable Day_2 "Monday"
label variable Day_3 "Tuesday"
label variable Day_4 "Wednesday"
label variable Day_5 "Thursday"
label variable Day_6 "Friday"
label variable Day_7 "Saturday"

label variable TimeTrend "Linear Time Trend"

label variable heating "Heating Consumption"
label variable baseload "Baseload Consumption"

* Initialize grouping variables that will be needed for the regressions to distinguish between the two different subsamples.
gen byte sample_pre_crisis = Date < td("01/12/2021")
gen byte sample_crisis = Date >= td("01/12/2021")
	
* Identify the Covid-19 pandemic window.
gen byte lockdown1 = Date >= td("08/03/2020") & Date <= td("04/05/2020")
gen byte lockdown2 = Date >= td("08/03/2020") & Date <= td("18/05/2020")
gen byte lockdown3 = Date >= td("08/03/2020") & Date <= td("03/06/2020")
gen byte lockdown4 = Date >= td("06/11/2020") & Date <= td("13/12/2020")


************************* REGRESSION: LOCKDOWN FEs ************************
* Model 1: Base model without lockdown
qui ardl RDS HDD SNSR price_l3m if sample_pre_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) ec lags(15 8 1 1)
matrix lr1 = e(b)
scalar RDS_lr1 = lr1[1,1]
scalar HDD_lr1 = lr1[1,2]
scalar SNSR_lr1 = lr1[1,3]
scalar price_lr1 = lr1[1,4]

* Model 2: With lockdown1
qui ardl RDS HDD SNSR price_l3m if sample_pre_crisis, bic trendvar exog(lockdown1 Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) ec lags(15 8 1 1)
matrix lr2 = e(b)
scalar RDS_lr2= lr2[1,1]
scalar HDD_lr2 = lr2[1,2]
scalar SNSR_lr2 = lr2[1,3]
scalar price_lr2 = lr2[1,4]

* Model 3: With lockdown2
qui ardl RDS HDD SNSR price_l3m if sample_pre_crisis, bic trendvar exog(lockdown2 Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) ec lags(15 8 1 1)
matrix lr3 = e(b)
scalar RDS_lr3 = lr3[1,1]
scalar HDD_lr3 = lr3[1,2]
scalar SNSR_lr3 = lr3[1,3]
scalar price_lr3 = lr3[1,4]

* Model 4: With lockdown3
qui ardl RDS HDD SNSR price_l3m if sample_pre_crisis, bic trendvar exog(lockdown3 Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) ec lags(15 8 1 1)
matrix lr4 = e(b)
scalar RDS_lr4 = lr4[1,1]
scalar HDD_lr4 = lr4[1,2]
scalar SNSR_lr4 = lr4[1,3]
scalar price_lr4 = lr4[1,4]

* Model 5: With lockdown4 (second lockdown: Nov 6 - Dec 13, 2020)
qui ardl RDS HDD SNSR price_l3m if sample_pre_crisis, bic trendvar exog(lockdown4 Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) ec lags(15 8 1 1)
matrix lr5 = e(b)
scalar RDS_lr5 = lr5[1,1]
scalar HDD_lr5 = lr5[1,2]
scalar SNSR_lr5 = lr5[1,3]
scalar price_lr5 = lr5[1,4]

* Display results
display _newline "Long-Run Coefficients on RDS:"
display _newline "Model 1 (Baseline):      " %9.4f RDS_lr1 "
display "Model 2 (lockdown1): " %9.4f RDS_lr2
display "Model 3 (lockdown2): " %9.4f RDS_lr3
display "Model 4 (lockdown3): " %9.4f RDS_lr4
display "Model 5 (lockdown4): " %9.4f RDS_lr5

display _newline "Long-Run Coefficients on HDD:"
display _newline "Model 1 (Baseline):      " %9.4f HDD_lr1 "
display "Model 2 (lockdown1): " %9.4f HDD_lr2
display "Model 3 (lockdown2): " %9.4f HDD_lr3
display "Model 4 (lockdown3): " %9.4f HDD_lr4
display "Model 5 (lockdown4): " %9.4f HDD_lr5

display _newline "Long-Run Coefficients on SNSR:"
display _newline "Model 1 (Baseline):      " %9.4f SNSR_lr1 "
display "Model 2 (lockdown1): " %9.4f SNSR_lr2
display "Model 3 (lockdown2): " %9.4f SNSR_lr3
display "Model 4 (lockdown3): " %9.4f SNSR_lr4
display "Model 5 (lockdown4): " %9.4f SNSR_lr5

display _newline "Long-Run Coefficients on price_l3m:"
display _newline "Model 1 (Baseline):      " %9.4f price_lr1 "
display "Model 2 (lockdown1): " %9.4f price_lr2
display "Model 3 (lockdown2): " %9.4f price_lr3
display "Model 4 (lockdown3): " %9.4f price_lr4
display "Model 5 (lockdown4): " %9.4f price_lr5



************************* REGRESSION: NO LOCKDOWN SAMPLES ************************
* Model 1: Base model without lockdown
qui ardl RDS HDD SNSR price_l3m if sample_pre_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) ec lags(15 8 1 1)
matrix lr1 = e(b)
scalar RDS_lr1 = lr1[1,1]
scalar HDD_lr1 = lr1[1,2]
scalar SNSR_lr1 = lr1[1,3]
scalar price_lr1 = lr1[1,4]

* Model 2: With lockdown1
qui ardl RDS HDD SNSR price_l3m if lockdown1 == 0 & sample_pre_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) ec lags(15 8 1 1)
matrix lr2 = e(b)
scalar RDS_lr2= lr2[1,1]
scalar HDD_lr2 = lr2[1,2]
scalar SNSR_lr2 = lr2[1,3]
scalar price_lr2 = lr2[1,4]

* Model 3: With lockdown2
qui ardl RDS HDD SNSR price_l3m if lockdown2 == 0 & sample_pre_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) ec lags(9 8 7 1)
matrix lr3 = e(b)
scalar RDS_lr3 = lr3[1,1]
scalar HDD_lr3 = lr3[1,2]
scalar SNSR_lr3 = lr3[1,3]
scalar price_lr3 = lr3[1,4]

* Model 4: With lockdown3
qui ardl RDS HDD SNSR price_l3m if lockdown3 == 0 & sample_pre_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) ec lags(15 8 1 1)
matrix lr4 = e(b)
scalar RDS_lr4 = lr4[1,1]
scalar HDD_lr4 = lr4[1,2]
scalar SNSR_lr4 = lr4[1,3]
scalar price_lr4 = lr4[1,4]

* Model 5: Excluding lockdown4 (second lockdown: Nov 6 - Dec 13, 2020)
qui ardl RDS HDD SNSR price_l3m if lockdown4 == 0 & sample_pre_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) ec lags(15 8 1 1)
matrix lr5 = e(b)
scalar RDS_lr5 = lr5[1,1]
scalar HDD_lr5 = lr5[1,2]
scalar SNSR_lr5 = lr5[1,3]
scalar price_lr5 = lr5[1,4]

* Display results
display _newline "Long-Run Coefficients on RDS:"
display _newline "Model 1 (Baseline):      " %9.4f RDS_lr1 "
display "Model 2 (lockdown1): " %9.4f RDS_lr2
display "Model 3 (lockdown2): " %9.4f RDS_lr3
display "Model 4 (lockdown3): " %9.4f RDS_lr4
display "Model 5 (lockdown4): " %9.4f RDS_lr5

display _newline "Long-Run Coefficients on HDD:"
display _newline "Model 1 (Baseline):      " %9.4f HDD_lr1 "
display "Model 2 (lockdown1): " %9.4f HDD_lr2
display "Model 3 (lockdown2): " %9.4f HDD_lr3
display "Model 4 (lockdown3): " %9.4f HDD_lr4
display "Model 5 (lockdown4): " %9.4f HDD_lr5

display _newline "Long-Run Coefficients on SNSR:"
display _newline "Model 1 (Baseline):      " %9.4f SNSR_lr1 "
display "Model 2 (lockdown1): " %9.4f SNSR_lr2
display "Model 3 (lockdown2): " %9.4f SNSR_lr3
display "Model 4 (lockdown3): " %9.4f SNSR_lr4
display "Model 5 (lockdown4): " %9.4f SNSR_lr5

display _newline "Long-Run Coefficients on price_l3m:"
display _newline "Model 1 (Baseline):      " %9.4f price_lr1 "
display "Model 2 (lockdown1): " %9.4f price_lr2
display "Model 3 (lockdown2): " %9.4f price_lr3
display "Model 4 (lockdown3): " %9.4f price_lr4
display "Model 5 (lockdown4): " %9.4f price_lr5



***************************** PREDICTED CONSUMPTION ****************************

* Tempfiles to store each savings series for the combined graph.
tempfile tf_lock1 tf_lock2 tf_lock3 tf_lock4 tf_lock34 tf_baseline

* --- Lockdown 1 (Mar 8 - May 4, 2020) ---
preserve
drop if lockdown1 == 1
ardl RDS HDD SNSR price_l3m if sample_pre_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) lags(15 8 1 1)
estimates store my_ardl_model
forecast create myforecast, replace
forecast estimates my_ardl_model
forecast solve, prefix(predicted_) begin(td("01/12/2021"))
keep if Date >= td("01/12/2021")
gen int mdate = mofd(Date)
format mdate %tm
collapse (sum) RDS predicted_RDS, by(mdate)
tsset mdate, monthly
gen savings_lock1 = predicted_RDS - RDS
keep mdate savings_lock1
save `tf_lock1'
restore

* --- Lockdown 2 (Mar 8 - May 18, 2020) ---
preserve
drop if lockdown2 == 1
ardl RDS HDD SNSR price_l3m if sample_pre_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) lags(15 8 1 1)
estimates store my_ardl_model
forecast create myforecast, replace
forecast estimates my_ardl_model
forecast solve, prefix(predicted_) begin(td("01/12/2021"))
keep if Date >= td("01/12/2021")
gen int mdate = mofd(Date)
format mdate %tm
collapse (sum) RDS predicted_RDS, by(mdate)
tsset mdate, monthly
gen savings_lock2 = predicted_RDS - RDS
keep mdate savings_lock2
save `tf_lock2'
restore

* --- Lockdown 3 (Mar 8 - Jun 3, 2020) ---
preserve
drop if lockdown3 == 1
ardl RDS HDD SNSR price_l3m if sample_pre_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) lags(15 8 1 1)
estimates store my_ardl_model
forecast create myforecast, replace
forecast estimates my_ardl_model
forecast solve, prefix(predicted_) begin(td("01/12/2021"))
keep if Date >= td("01/12/2021")
gen int mdate = mofd(Date)
format mdate %tm
collapse (sum) RDS predicted_RDS, by(mdate)
tsset mdate, monthly
gen savings_lock3 = predicted_RDS - RDS
keep mdate savings_lock3
save `tf_lock3'
restore

* --- Lockdown 4: second lockdown (Nov 6 - Dec 13, 2020) ---
preserve
drop if lockdown4 == 1
ardl RDS HDD SNSR price_l3m if sample_pre_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) lags(15 8 1 1)
estimates store my_ardl_model
forecast create myforecast, replace
forecast estimates my_ardl_model
forecast solve, prefix(predicted_) begin(td("01/12/2021"))
keep if Date >= td("01/12/2021")
gen int mdate = mofd(Date)
format mdate %tm
collapse (sum) RDS predicted_RDS, by(mdate)
tsset mdate, monthly
gen savings_lock4 = predicted_RDS - RDS
keep mdate savings_lock4
save `tf_lock4'
restore

* --- Lockdown 3 + 4 combined (Mar 8 - Jun 3, 2020 and Nov 6 - Dec 13, 2020) ---
preserve
drop if lockdown3 == 1 | lockdown4 == 1
ardl RDS HDD SNSR price_l3m if sample_pre_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) lags(15 8 1 1)
estimates store my_ardl_model
forecast create myforecast, replace
forecast estimates my_ardl_model
forecast solve, prefix(predicted_) begin(td("01/12/2021"))
keep if Date >= td("01/12/2021")
gen int mdate = mofd(Date)
format mdate %tm
collapse (sum) RDS predicted_RDS, by(mdate)
tsset mdate, monthly
gen savings_lock34 = predicted_RDS - RDS
keep mdate savings_lock34
save `tf_lock34'
restore

* --- Baseline: model estimated on full pre-crisis sample ---
preserve
ardl RDS HDD SNSR price_l3m if sample_pre_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) lags(15 8 1 1)
estimates store my_ardl_model
forecast create myforecast, replace
forecast estimates my_ardl_model
forecast solve, prefix(predicted_) begin(td("01/12/2021"))
keep if Date >= td("01/12/2021")
gen int mdate = mofd(Date)
format mdate %tm
collapse (sum) RDS predicted_RDS, by(mdate)
tsset mdate, monthly
gen savings_baseline = predicted_RDS - RDS
keep mdate savings_baseline
save `tf_baseline'
restore

* --- Combined graph: all savings series vs baseline ---
use `tf_baseline', clear
merge 1:1 mdate using `tf_lock1',  nogen
merge 1:1 mdate using `tf_lock2',  nogen
merge 1:1 mdate using `tf_lock3',  nogen
merge 1:1 mdate using `tf_lock4',  nogen
merge 1:1 mdate using `tf_lock34', nogen
tsset mdate, monthly

twoway ///
	(tsline savings_baseline, lcolor(black)  lwidth(medthick) lpattern(solid)) ///
	(tsline savings_lock1,    lcolor(blue)   lwidth(medium)   lpattern(dash)) ///
	(tsline savings_lock2,    lcolor(red)    lwidth(medium)   lpattern(dash)) ///
	(tsline savings_lock3,    lcolor(green)  lwidth(medium)   lpattern(dash)) ///
	(tsline savings_lock4,    lcolor(orange) lwidth(medium)   lpattern(shortdash)) ///
	(tsline savings_lock34,   lcolor(purple) lwidth(medium)   lpattern(shortdash)), ///
	ytick(-300(100)900) ylabel(-300(100)900) xtitle("") ytitle("") ///
	legend(order(1 "Baseline" 2 "Lockdown 1(a) (Mar–May 4)" 3 "Lockdown 1(b) (Mar–May 18)" 4 "Lockdown 1(c) (Mar–Jun 3)" 5 "Lockdown 2 (Nov–Dec 2020)" 6 "Lockdown 1(c)&2") pos(6) ring(1) cols(2)) ///
	name(g_savings_combined, replace)
graph export g_savings_combined.png, as(png) replace








}


*------------------------------------------------------------------------------*
*------------------------------------- IV -------------------------------------*
*------------------------------------------------------------------------------*

{
	
* Import the working database.
clear

import excel "", firstrow

* Set the WD.
cd ""

* Rename the date variable for consistency with the code.
format date %tdDD/NN/CCYY
rename date Date

* Declare data to be time-series.
tsset Date, daily

* Label accordingly variables.
label variable Month_1 "January"
label variable Month_2 "February"
label variable Month_3 "March"
label variable Month_4 "April"
label variable Month_5 "May"
label variable Month_6 "June"
label variable Month_7 "July"
label variable Month_8 "August"
label variable Month_9 "September"
label variable Month_10 "October"
label variable Month_11 "November"
label variable Month_12 "December"

label variable Day_1 "Sunday"
label variable Day_2 "Monday"
label variable Day_3 "Tuesday"
label variable Day_4 "Wednesday"
label variable Day_5 "Thursday"
label variable Day_6 "Friday"
label variable Day_7 "Saturday"

label variable TimeTrend "Linear Time Trend"

label variable heating "Heating Consumption"
label variable baseload "Baseload Consumption"
label variable index_m "Ristorazione Index"

* Initialize grouping variables that will be needed for the regressions to distinguish between the two different subsamples.
gen byte sample_pre_crisis = Date < td("01/12/2021")
gen byte sample_crisis = Date >= td("01/12/2021")

* 1) Generate the Δ terms.
gen dRDS = D.RDS
gen dHDD = D.HDD
gen dSNSR = D.SNSR
gen dprice = D.price_l3m
gen dttf = D.ttf_l6m



* ardl RDS HDD SNSR price_l3m, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) ec lags(15 8 1 0)

* ardl RDS HDD SNSR price_l3m if sample_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) ec lags(9 8 1 0)


*********************** MANUAL OLS REGRESSIONS BY SAMPLE ***********************

* Pre-crisis
* reg dRDS L.RDS HDD SNSR price_l3m L(1/14).dRDS L(0/7).dHDD dSNSR dprice Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7 TimeTrend if sample_pre_crisis

* Full sample
reg dRDS L.RDS HDD SNSR price_l3m L(1/14).dRDS L(0/7).dHDD dSNSR Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7 TimeTrend

* Crisis
reg dRDS L.RDS HDD SNSR price_l3m L(1/8).dRDS L(0/7).dHDD dSNSR Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7 TimeTrend if sample_crisis

*********************** MANUAL IV REGRESSIONS BY SAMPLE ************************

* Pre-crisis
* ivreg2 dRDS L.RDS HDD SNSR (price_l3m dprice = ttf_l6m dttf) L(1/14).dRDS L(0/7).dHDD dSNSR Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7 TimeTrend if sample_pre_crisis

* Full sample
ivreg2 dRDS L.RDS HDD SNSR (price_l3m = ttf_l6m) L(1/14).dRDS L(0/7).dHDD dSNSR Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7 TimeTrend, robust bw(auto) first savefirst
local kp_lm_full = e(idstat)
eststo iv_full
estadd scalar rklm = `kp_lm_full'
estimates restore _ivreg2_price_l3m
quietly test ttf_l6m
estadd scalar F_excl = r(F)
eststo fs_full

* Crisis
ivreg2 dRDS L.RDS HDD SNSR (price_l3m = ttf_l6m) L(1/8).dRDS L(0/7).dHDD dSNSR Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7 TimeTrend if sample_crisis, robust bw(auto) first savefirst
local kp_lm_crisis = e(idstat)
eststo iv_crisis
estadd scalar rklm = `kp_lm_crisis'
estimates restore _ivreg2_price_l3m
quietly test ttf_l6m
estadd scalar F_excl = r(F)
eststo fs_crisis

* Export IV second-stage table
esttab iv_full iv_crisis using "IV_Results.tex", replace b(3) se(3) ///
	star(* 0.10 ** 0.05 *** 0.01) scalars("rklm KP rk LM stat." "widstat KP Wald F-stat" "N Observations") sfmt(3 3 0) ///
	label mtitle("Full Sample" "Crisis Sample") collabels(none) ///
	keep(L.RDS HDD SNSR price_l3m) compress ///
	varlabels(L.RDS "Error Correction" HDD "Heating‐Degree Days" SNSR "Solar Radiation" price_l3m "Lagged Price Index (IV)") ///
	postfoot("\midrule" "Monthly Seasonal Dummies & Yes & Yes \\" "Daily Seasonal Dummies & Yes & Yes \\" "AR Lags & Yes & Yes \\")

* Export first-stage table
esttab fs_full fs_crisis using "IV_FirstStage.tex", replace b(3) se(3) ///
	star(* 0.10 ** 0.05 *** 0.01) scalars("F_excl First-stage F-stat" "N Observations") sfmt(3 0) ///
	label mtitle("Full Sample" "Crisis Sample") collabels(none) ///
	keep(ttf_l6m) compress ///
	varlabels(ttf_l6m "TTF Price (6m lag)") ///
	postfoot("\midrule" "Monthly Seasonal Dummies & Yes & Yes \\" "Daily Seasonal Dummies & Yes & Yes \\" "AR Lags & Yes & Yes \\")



}


*------------------------------------------------------------------------------*
*--------------------------- SAVINGS (ROLLING WINDOW) -------------------------*
*------------------------------------------------------------------------------*

{

* Import the working database.
clear

import excel "", firstrow

* Set the WD.
cd ""

* Rename the date variable for consistency with the code.
format date %tdDD/NN/CCYY
rename date Date

* Declare data to be time-series.
tsset Date, daily

* Label variables.
label variable Month_1  "January"
label variable Month_2  "February"
label variable Month_3  "March"
label variable Month_4  "April"
label variable Month_5  "May"
label variable Month_6  "June"
label variable Month_7  "July"
label variable Month_8  "August"
label variable Month_9  "September"
label variable Month_10 "October"
label variable Month_11 "November"
label variable Month_12 "December"

label variable Day_1 "Sunday"
label variable Day_2 "Monday"
label variable Day_3 "Tuesday"
label variable Day_4 "Wednesday"
label variable Day_5 "Thursday"
label variable Day_6 "Friday"
label variable Day_7 "Saturday"

label variable TimeTrend "Linear Time Trend"
label variable heating   "Heating Consumption"
label variable baseload  "Baseload Consumption"
label variable index_m   "Ristorazione Index"

* Initialize grouping variables.
gen byte sample_pre_crisis = Date < td("01/12/2021")
gen byte sample_crisis     = Date >= td("01/12/2021")
gen int  year              = year(Date)

* ══════════════════════════════════════════════════════════════════════════════
* EXPANDING-WINDOW SAVINGS ROBUSTNESS CHECK
* ══════════════════════════════════════════════════════════════════════════════

forvalues c = 2016/2021 {
    capture drop cf_`c'
    gen double cf_`c' = .
}

forvalues c = 2016/2021 {
    display as txt _n "--- Training on 2012-`c', forecasting 2022-2025 ---"

    quietly ardl RDS HDD SNSR price_l3m if Date <= td("31dec`c'") & sample_pre_crisis, trendvar bic maxlags(15) exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7)

    quietly estimates store ardl_`c'
    quietly forecast create fc_cf, replace
    quietly forecast estimates ardl_`c'
    capture drop roll_RDS
    quietly forecast solve, prefix(roll_) begin(td("01jan2022"))
    quietly replace cf_`c' = roll_RDS if year >= 2022 & year <= 2025
    quietly drop roll_RDS
}

* ── Compute savings and yearly totals ────────────────────────────────────────

forvalues c = 2016/2021 {
    capture drop sav_`c'
    gen double sav_`c' = cf_`c' - RDS if year >= 2022 & year <= 2025

    foreach y in 2022 2023 2024 2025 {
        quietly summarize sav_`c' if year == `y'
        local s_`c'_`y' = r(sum)
    }
    local s_`c'_total = `s_`c'_2022' + `s_`c'_2023' + `s_`c'_2024' + `s_`c'_2025'
}

* ── Export LaTeX table ────────────────────────────────────────────────────────

local fn "savings_robustness.tex"
file open fh using "`fn'", write replace

file write fh "\begin{table}[htbp]" _n
file write fh "\centering" _n
file write fh "\caption{Estimated Savings by Training Window (millions Sm\textsuperscript{3})}" _n
file write fh "\label{tab:savings_robustness}" _n
file write fh "\begin{tabular}{lccccc}" _n
file write fh "\toprule" _n
file write fh "Training Sample & 2022 & 2023 & 2024 & 2025 & Total \\" _n
file write fh "\midrule" _n

forvalues c = 2016/2021 {
    if `c' == 2021 {
        local rowlabel "2012--2021\textsuperscript{\dag}"
    }
    else {
        local rowlabel "2012--`c'"
    }
    local v22  = string(`s_`c'_2022',  "%9.0f")
    local v23  = string(`s_`c'_2023',  "%9.0f")
    local v24  = string(`s_`c'_2024',  "%9.0f")
    local v25  = string(`s_`c'_2025',  "%9.0f")
    local vtot = string(`s_`c'_total', "%9.0f")
    file write fh "`rowlabel' & `v22' & `v23' & `v24' & `v25' & `vtot' \\" _n
}

file write fh "\midrule" _n
file write fh "\multicolumn{6}{l}{\textit{Difference from baseline (millions Sm\textsuperscript{3})}} \\" _n
file write fh "\midrule" _n

forvalues c = 2016/2020 {
    foreach stub in 2022 2023 2024 2025 total {
        local raw = `s_`c'_`stub'' - `s_2021_`stub''
        local d`stub' = cond(`raw' >= 0, "+", "") + string(`raw', "%9.0f")
    }
    file write fh "2012--`c' & `d2022' & `d2023' & `d2024' & `d2025' & `dtotal' \\" _n
}

file write fh "\bottomrule" _n
file write fh "\end{tabular}" _n
file write fh "\end{table}" _n

file close fh

* ── Plot 1: monthly savings by training window ───────────────────────────────

preserve
    keep if year >= 2022 & year <= 2025
    gen int mdate = mofd(Date)
    format mdate %tm
    collapse (sum) sav_2016 sav_2017 sav_2018 sav_2019 sav_2020 sav_2021 RDS, by(mdate)
    tsset mdate, monthly

    twoway ///
        (tsline sav_2021, lcolor(black)   lwidth(medthick) lpattern(solid))     ///
        (tsline sav_2016, lcolor(teal)    lwidth(medium)   lpattern(dash))      ///
        (tsline sav_2017, lcolor(blue)    lwidth(medium)   lpattern(shortdash)) ///
        (tsline sav_2018, lcolor(red)     lwidth(medium)   lpattern(shortdash)) ///
        (tsline sav_2019, lcolor(orange)  lwidth(medium)   lpattern(longdash))  ///
        (tsline sav_2020, lcolor(green)   lwidth(medium)   lpattern(longdash)), ///
        yline(0, lcolor(gs10) lpattern(dot)) ///
        ytitle("Monthly savings (RDS units)") xtitle("") ///
        legend(order(1 "Baseline (2012–2021)" ///
                     2 "2012–2016"            ///
                     3 "2012–2017"            ///
                     4 "2012–2018"            ///
                     5 "2012–2019"            ///
                     6 "2012–2020")           ///
               pos(6) ring(1) cols(3))        ///
        title("Monthly Savings by Training Window") ///
        note("Savings = predicted RDS – actual RDS. ARDL with BIC lag selection (maxlags 15).") ///
        name(g_savings_monthly, replace)
    graph export "savings_monthly_by_window.png", as(png) replace
restore

* ── Plot 2: annual savings bar chart ─────────────────────────────────────────

preserve
    keep if year >= 2022 & year <= 2025
    collapse (sum) sav_2016 sav_2017 sav_2018 sav_2019 sav_2020 sav_2021, by(year)

    graph bar sav_2021 sav_2016 sav_2017 sav_2018 sav_2019 sav_2020, ///
        over(year) ///
        bar(1, fcolor(black)      lcolor(black))     ///
        bar(2, fcolor(teal%70)    lcolor(teal))      ///
        bar(3, fcolor(blue%70)    lcolor(blue))      ///
        bar(4, fcolor(red%70)     lcolor(red))       ///
        bar(5, fcolor(orange%70)  lcolor(orange))    ///
        bar(6, fcolor(green%70)   lcolor(green))     ///
        legend(order(1 "Baseline (2012–2021)" ///
                     2 "2012–2016"            ///
                     3 "2012–2017"            ///
                     4 "2012–2018"            ///
                     5 "2012–2019"            ///
                     6 "2012–2020")           ///
               pos(6) ring(1) cols(3))        ///
        ytitle("Annual savings (RDS units)") ///
        title("Annual Savings by Training Window") ///
        note("ARDL with BIC lag selection (maxlags 15). Positive = below-baseline consumption.") ///
        name(g_savings_annual, replace)
    graph export "savings_annual_by_window.png", as(png) replace
restore

graph drop _all

}


*------------------------------------------------------------------------------*
*----------------------------- SAVINGS (BOOTSTRAP) ----------------------------*
*------------------------------------------------------------------------------*

{

*********************************** CLEANING ***********************************

* Import the working database.
clear

*===============================================================================
* Complete with the file path to the daily data set.
*===============================================================================
import excel "", firstrow

*===============================================================================
* Set the working directory.
*===============================================================================
cd ""

* Rename the date variable for consistency with the code.
format date %tdDD/NN/CCYY
rename date Date

* Declare data to be time-series.
tsset Date, daily

* Label accordingly variables.
label variable Month_1 "January"
label variable Month_2 "February"
label variable Month_3 "March"
label variable Month_4 "April"
label variable Month_5 "May"
label variable Month_6 "June"
label variable Month_7 "July"
label variable Month_8 "August"
label variable Month_9 "September"
label variable Month_10 "October"
label variable Month_11 "November"
label variable Month_12 "December"

label variable Day_1 "Sunday"
label variable Day_2 "Monday"
label variable Day_3 "Tuesday"
label variable Day_4 "Wednesday"
label variable Day_5 "Thursday"
label variable Day_6 "Friday"
label variable Day_7 "Saturday"

label variable TimeTrend "Linear Time Trend"

label variable heating "Heating Consumption"
label variable baseload "Baseload Consumption"

* Initialize grouping variables.
gen byte sample_pre_crisis = Date < td("01/12/2021")
gen byte sample_crisis     = Date >= td("01/12/2021")
set more off
set seed 20250601

tsset Date, daily

* ══════════════════════════════════════════════════════════════════════════════
* SETTINGS
* ══════════════════════════════════════════════════════════════════════════════

local B           = 10000
local block_size  = 30
local fcast_start = "01dec2021"

* ══════════════════════════════════════════════════════════════════════════════
* STEP 0: PREPARATION
* ══════════════════════════════════════════════════════════════════════════════

capture drop year
gen int year = year(Date)

* Keep a permanent copy of RDS.
capture drop RDS_original
gen double RDS_original = RDS

* Create a trend variable matching ardl's trendvar exactly:
* ardl trendvar internally generates t = Date - min(estimation Date) + 1.
* Replicating this here so regress (used in the loop) is numerically identical.
capture drop _trend_bts
quietly summarize Date if sample_pre_crisis, meanonly
gen long _trend_bts = Date - r(min) + 1

* ══════════════════════════════════════════════════════════════════════════════
* STEP 1: BASELINE MODEL — FITTED VALUES, RESIDUALS, AND POINT FORECAST
* ══════════════════════════════════════════════════════════════════════════════

display _n as txt "--- Estimating baseline ARDL(15,8,1,1) on pre-crisis sample ---"

ardl RDS HDD SNSR price_l3m if sample_pre_crisis, ///
    trendvar lags(15 8 1 1) ///
    exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 ///
         Month_8 Month_9 Month_10 Month_11 Month_12 ///
         Day_2 Day_3 Day_4 Day_5 Day_6 Day_7)

* Fitted values and residuals (pre-crisis estimation sample only).
capture drop fitted_pre resid_pre
predict double fitted_pre if e(sample), xb
predict double resid_pre  if e(sample), residuals

* Point forecast — forecast framework used only once, for display.
estimates store ardl_baseline
forecast create fc_point, replace
forecast estimates ardl_baseline
forecast solve, prefix(pt_) begin(td(`fcast_start'))

* Store actual yearly consumption.
forvalues y = 2022/2025 {
    quietly summarize RDS_original if year == `y'
    local actual_`y' = r(sum)
}

* Display point-estimate savings.
display _n as txt "=== POINT-ESTIMATE SAVINGS ==="
forvalues y = 2022/2025 {
    quietly summarize pt_RDS if year == `y'
    local pt_sav_`y' = r(sum) - `actual_`y''
    display as txt "  `y':  " as res %15.0fc `pt_sav_`y'' as txt " Sm3"
}

* ══════════════════════════════════════════════════════════════════════════════
* STEP 1b: VERIFY regress == ardl BEFORE THE LOOP (runs once)
* ══════════════════════════════════════════════════════════════════════════════

display _n as txt "--- Verifying regress equivalent of ardl ---"

quietly regress RDS ///
    L(1/15).RDS L(0/7).HDD SNSR price_l3m _trend_bts ///
    Month_2 Month_3 Month_4 Month_5 Month_6 Month_7   ///
    Month_8 Month_9 Month_10 Month_11 Month_12         ///
    Day_2 Day_3 Day_4 Day_5 Day_6 Day_7               ///
    if sample_pre_crisis

display as txt "  regress R2 = " as res %10.8f e(r2) ///
    as txt "  (must match ardl R2 — OLS equivalence check)"

* ══════════════════════════════════════════════════════════════════════════════
* STEP 2: LOAD RESIDUALS AND FITTED VALUES INTO MATA
* ══════════════════════════════════════════════════════════════════════════════

capture drop has_resid resid_seq
gen byte has_resid = !missing(resid_pre)
gen long resid_seq = sum(has_resid) if has_resid == 1

quietly summarize resid_seq, meanonly
local N_valid  = r(max)
local n_blocks = ceil(`N_valid' / `block_size')

display as txt "  Pre-crisis obs with valid residuals: `N_valid'"
display as txt "  Number of blocks (size `block_size'): `n_blocks'"

* Load pre-crisis residuals, fitted values, and original RDS into Mata globals.
* These persist across all loop iterations with no disk I/O.
mata:
    _mask      = (st_data(., "has_resid") :== 1)
    pre_rows   = select((1::st_nobs()), _mask)             // Stata row indices
    resid_mat  = select(st_data(., "resid_pre"),    _mask) // baseline residuals
    fitted_mat = select(st_data(., "fitted_pre"),   _mask) // baseline fitted
    rds_orig   = select(st_data(., "RDS_original"), _mask) // original RDS
    N_valid_m  = rows(resid_mat)
    n_blk_m    = ceil(N_valid_m / `block_size')
    _mask      = .
end

* ══════════════════════════════════════════════════════════════════════════════
* STEP 2b: BUILD EXOGENOUS VARIABLE MATRIX FOR FORECAST PERIOD
* ══════════════════════════════════════════════════════════════════════════════

* Create explicit HDD lag variables needed for the X_exog matrix.
forvalues lag = 1/7 {
    capture drop _hdd_l`lag'
    quietly gen double _hdd_l`lag' = L`lag'.HDD
}

* Pre-generate boot_RDS once (avoids create/drop overhead inside the loop).
capture drop boot_RDS
gen double boot_RDS = .

* Build X_exog_fc in Mata (T_crisis × 29 matrix, constant already appended).
* ar_init_rows: the 15 pre-crisis rows immediately before the forecast start.
*   These hold the AR initial conditions for each iteration (synthetic RDS).
*   Assumption: no gaps in the last 15 days of the pre-crisis period — valid
*   for daily consumption data. pre_rows is chronologically sorted because
*   the dataset is tsset Date, daily.
mata:
    fc_rows = selectindex(st_data(., "sample_crisis") :== 1)

    exog_vars = ("HDD",       "_hdd_l1",  "_hdd_l2",  "_hdd_l3",  "_hdd_l4",  ///
                 "_hdd_l5",   "_hdd_l6",  "_hdd_l7",  "SNSR",     "price_l3m", ///
                 "_trend_bts","Month_2",  "Month_3",  "Month_4",  "Month_5",   ///
                 "Month_6",   "Month_7",  "Month_8",  "Month_9",  "Month_10",  ///
                 "Month_11",  "Month_12", "Day_2",    "Day_3",    "Day_4",     ///
                 "Day_5",     "Day_6",    "Day_7")

    // T_crisis × 29: observed exogenous values + constant column
    X_exog_fc  = (st_data(fc_rows, exog_vars), J(rows(fc_rows), 1, 1))

    // Row indices of the last 15 pre-crisis obs (initial AR conditions)
    ar_init_rows = pre_rows[(N_valid_m - 14)..N_valid_m]

    p_ar = 15   // number of AR lags
end

* ══════════════════════════════════════════════════════════════════════════════
* STEP 2c: DEFINE MATA FUNCTIONS
* ══════════════════════════════════════════════════════════════════════════════

* Drop functions if they already exist (e.g. from a previous run in same session).
capture mata: mata drop block_resample_bts()
capture mata: mata drop ardl_dynforecast()

mata:

// Block resampler:
// Draws blocks with replacement until N_valid residuals are accumulated,
// then truncates. The while-loop handles partial last blocks robustly.
real colvector block_resample_bts(  ///
    real colvector resids,          ///
    real scalar    block_sz,        ///
    real scalar    N_valid,         ///
    real scalar    n_blk)
{
    real colvector result
    real scalar    b_id, b_start, b_end, pos

    result = J(N_valid + block_sz, 1, .)
    pos    = 0

    while (pos < N_valid) {
        b_id    = floor(runiform(1,1) * n_blk) + 1
        b_start = (b_id - 1) * block_sz + 1
        b_end   = min((b_id * block_sz, N_valid))
        result[(pos + 1)..(pos + b_end - b_start + 1)] = resids[b_start..b_end]
        pos = pos + b_end - b_start + 1
    }

    return(result[1..N_valid])
}

// Dynamic ARDL forecast:
// b_all  : full e(b) rowvector from regress (1 x 44)
//          cols  1..p    : AR coefficients for L1.RDS ... Lp.RDS
//          cols p+1..end : exogenous coefficients + constant
// X_exog : T_fc x (44-p) matrix of exogenous vars + constant for forecast obs
//          columns must match e(b) positions p+1 ... 44 exactly
// y_init : p x 1 column vector of the last p pre-crisis RDS values
//          y_init[1] = oldest (lag p), y_init[p] = most recent (lag 1)
real colvector ardl_dynforecast(    ///
    real rowvector b_all,           ///
    real matrix    X_exog,          ///
    real colvector y_init,          ///
    real scalar    p)
{
    real rowvector b_ar, b_exog
    real colvector y_last, yhat
    real scalar    T_fc, t

    b_ar   = b_all[1..p]               // 1 x p  AR coefficients
    b_exog = b_all[(p+1)..cols(b_all)] // 1 x (K-p) exogenous + constant

    // y_last[1] = lag 1 (most recent), y_last[p] = lag p (oldest)
    y_last = y_init[p..1]

    T_fc = rows(X_exog)
    yhat = J(T_fc, 1, 0)

    for (t = 1; t <= T_fc; t++) {
        yhat[t] = (b_ar * y_last + b_exog * X_exog[t,.]')[1,1]
        y_last  = (yhat[t] \ y_last[1..(p-1)])
    }

    return(yhat)
}

end

* ══════════════════════════════════════════════════════════════════════════════
* STEP 3: BOOTSTRAP LOOP
* ══════════════════════════════════════════════════════════════════════════════

tempname pf
tempfile boot_results
postfile `pf' double(sav2022 sav2023 sav2024 sav2025) using `boot_results'

local n_failures = 0

timer clear 1
timer on 1

display _n as txt "--- Starting bootstrap (`B' replications) ---"

forvalues b = 1/`B' {

    * ── 3a. Block-resample residuals in Mata; write synthetic RDS ──────────
    * One Mata call: in-memory resampling + st_store back to dataset.
    * Replaces: preserve / clear / set obs / joinby / restore.
    mata: st_store(pre_rows, st_varindex("RDS"),                              ///
                   fitted_mat :+ block_resample_bts(resid_mat, `block_size',  ///
                                  N_valid_m, n_blk_m))

    * ── 3b. Re-estimate on synthetic pre-crisis data ───────────────────────
    * regress is numerically identical to ardl (both are OLS on the same
    * design matrix) but has lower per-call overhead.
    capture quietly regress RDS                                               ///
        L(1/15).RDS L(0/7).HDD SNSR price_l3m _trend_bts                    ///
        Month_2 Month_3 Month_4 Month_5 Month_6 Month_7                      ///
        Month_8 Month_9 Month_10 Month_11 Month_12                           ///
        Day_2 Day_3 Day_4 Day_5 Day_6 Day_7                                  ///
        if sample_pre_crisis

    if _rc != 0 {
        local ++n_failures
        continue
    }

    * ── 3c. Dynamic forecast in Mata ───────────────────────────────────────
    * Replaces: forecast create / forecast estimates / forecast solve.
    * ardl_dynforecast() extracts e(b), reads the last p=15 synthetic
    * pre-crisis RDS values as initial conditions, and recursively applies
    * the ARDL formula across all crisis-period observations.
    capture mata: st_store(fc_rows, st_varindex("boot_RDS"),                  ///
                   ardl_dynforecast(st_matrix("e(b)"), X_exog_fc,             ///
                                    st_data(ar_init_rows, st_varindex("RDS")), ///
                                    p_ar))

    if _rc != 0 {
        local ++n_failures
        continue
    }

    * ── 3d. Compute and store yearly savings ───────────────────────────────
    local s2022 = .
    local s2023 = .
    local s2024 = .
    local s2025 = .

    forvalues y = 2022/2025 {
        quietly summarize boot_RDS if year == `y'
        if r(N) > 0 local s`y' = r(sum) - `actual_`y''
    }

    post `pf' (`s2022') (`s2023') (`s2024') (`s2025')

    * ── Progress indicator ─────────────────────────────────────────────────
    if mod(`b', 50) == 0 {
        display as txt "  Completed `b' / `B'"
    }

}   // end bootstrap loop

postclose `pf'

timer off 1
quietly timer list 1
display _n as txt "Bootstrap completed in " ///
    as res %6.1f `=r(t1)/60' as txt " minutes"
display as txt "Failed iterations: " as res `n_failures' as txt " / `B'"

* ══════════════════════════════════════════════════════════════════════════════
* STEP 4: RESTORE ORIGINAL DATA
* ══════════════════════════════════════════════════════════════════════════════

mata: st_store(pre_rows, st_varindex("RDS"), rds_orig)
quietly replace RDS = RDS_original   // belt-and-suspenders

* ══════════════════════════════════════════════════════════════════════════════
* STEP 5: EXTRACT CONFIDENCE INTERVALS AND EXPORT RESULTS
* ══════════════════════════════════════════════════════════════════════════════

preserve

    use `boot_results', clear

    drop if missing(sav2022) & missing(sav2023) & missing(sav2024) & missing(sav2025)

    local n_success = _N
    display _n as txt "  Successful bootstrap replications: `n_success'"

    gen double sav_total = sav2022 + sav2023 + sav2024 + sav2025

    * ── Compute statistics ────────────────────────────────────────────────

    foreach y in 2022 2023 2024 2025 {
        quietly _pctile sav`y', percentiles(2.5 50 97.5)
        local ci_lo_`y' = r(r1)
        local med_`y'   = r(r2)
        local ci_hi_`y' = r(r3)
    }

    local pt_total = `pt_sav_2022' + `pt_sav_2023' + `pt_sav_2024' + `pt_sav_2025'

    quietly _pctile sav_total, percentiles(2.5 50 97.5)
    local tot_lo  = r(r1)
    local tot_med = r(r2)
    local tot_hi  = r(r3)

    * ── LaTeX table ───────────────────────────────────────────────────────

    local fn "bootstrap_savings_results.tex"
    file open fh using "`fn'", write replace

    file write fh "\begin{table}[htbp]" _n
    file write fh "\centering" _n
    file write fh "\caption{Bootstrap Confidence Intervals for Counterfactual Gas Savings (millions Sm\textsuperscript{3})}" _n
    file write fh "\label{tab:bootstrap_savings}" _n
    file write fh "\begin{tabular}{lcccc}" _n
    file write fh "\toprule" _n
    file write fh " & & & \multicolumn{2}{c}{95\% Confidence Interval} \\" _n
    file write fh "\cmidrule(lr){4-5}" _n
    file write fh "Year & Point Estimate & Median & Lower & Upper \\" _n
    file write fh "\midrule" _n

    foreach y in 2022 2023 2024 2025 {
        local vpt  = string(`pt_sav_`y'',  "%9.0f")
        local vmed = string(`med_`y'',     "%9.0f")
        local vlo  = string(`ci_lo_`y'',   "%9.0f")
        local vhi  = string(`ci_hi_`y'',   "%9.0f")
        file write fh "`y' & `vpt' & `vmed' & `vlo' & `vhi' \\" _n
    }

    file write fh "\midrule" _n

    local vpt  = string(`pt_total',  "%9.0f")
    local vmed = string(`tot_med',   "%9.0f")
    local vlo  = string(`tot_lo',    "%9.0f")
    local vhi  = string(`tot_hi',    "%9.0f")
    file write fh "2022--2025 & `vpt' & `vmed' & `vlo' & `vhi' \\" _n

    file write fh "\bottomrule" _n
    file write fh "\end{tabular}" _n
    file write fh "\medskip" _n
    file write fh "{\footnotesize Confidence intervals derived from `n_success' residual block bootstrap replications (block size: `block_size' days). The point estimate is the savings implied by the baseline ARDL(15,8,1,1) estimated on the full pre-crisis sample; the median and confidence interval reflect parameter uncertainty across bootstrap re-estimations.}" _n
    file write fh "\end{table}" _n

    file close fh
    display as txt _n "LaTeX table written to: `fn'"

    * ── Histograms: yearly savings (4-panel combined graph) ───────────────

    histogram sav2022, bin(50) normal fcolor(navy%60) lcolor(navy) xtitle("Savings (millions Sm3)") title("2022") name(hist_2022, replace)
    histogram sav2023, bin(50) normal fcolor(navy%60) lcolor(navy) xtitle("Savings (millions Sm3)") title("2023") name(hist_2023, replace)
    histogram sav2024, bin(50) normal fcolor(navy%60) lcolor(navy) xtitle("Savings (millions Sm3)") title("2024") name(hist_2024, replace)
    histogram sav2025, bin(50) normal fcolor(navy%60) lcolor(navy) xtitle("Savings (millions Sm3)") title("2025") name(hist_2025, replace)

    graph combine hist_2022 hist_2023 hist_2024 hist_2025, cols(2) iscale(0.6) title("") name(hist_yearly, replace)
    graph export "bootstrap_savings_yearly.png", as(png) width(2000) replace

    * ── Histogram: total savings (standalone graph) ───────────────────────

    histogram sav_total, bin(50) normal fcolor(navy%60) lcolor(navy) xtitle("Savings (millions Sm3)") title("") name(hist_total, replace)
    graph export "bootstrap_savings_total.png", as(png) width(1200) replace

    * ── Save draws ────────────────────────────────────────────────────────
    save "bootstrap_savings_draws.dta", replace

restore


}


}




********************************************************************************
************************************ MONTHLY ***********************************
********************************************************************************

{
	
*********************************** CLEANING ***********************************

* Import the working database.

clear

*===============================================================================
* Complete with the file path to the daily data set.
*===============================================================================
import excel "", firstrow

*===============================================================================
* Set the working directory.
*===============================================================================
cd ""

* Declare data to be time-series.
tsset time, monthly

* Label accordingly variables.
label variable Month_1 "January"
label variable Month_2 "February"
label variable Month_3 "March"
label variable Month_4 "April"
label variable Month_5 "May"
label variable Month_6 "June"
label variable Month_7 "July"
label variable Month_8 "August"
label variable Month_9 "September"
label variable Month_10 "October"
label variable Month_11 "November"
label variable Month_12 "December"

label variable TimeTrend "Linear Time Trend"


gen double date_num = daily(date, "DMY")

format date_num %tdDD/NN/CCYY

drop date

rename date_num Date 

gen byte sample_pre_crisis = time < 743
gen byte sample_crisis = time >= 743

tsline RDS baseload heating, legend(row(1) pos(6) label(1 "Total Consumption") label(2 "Baseload Consumption") label(3 "Heating Consumption")) ytitle("") ttick(2012m1 2014m1 2016m1 2018m1 2020m1 2022m1 2024m1 2026m1) tlabel(2012m1 "Jan 2012" 2014m1 "Jan 2014" 2016m1 "Jan 2016" 2018m1 "Jan 2018" 2020m1 "Jan 2020"  2022m1 "Jan 2022" 2024m1 "Jan 2024" 2026m1 "Jan 2026") name(RDS_Base_Heat)
graph export RDS_Base_Heat.png, as(png) replace

graph drop _all


******************************** MODEL SELECTION *******************************
* ardl RDS HDD SNSR price_l3m, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12) maxlags(3)
* ardl RDS HDD SNSR price_l3m if sample_pre_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12) maxlags(3)
* ardl RDS HDD SNSR price_l3m if sample_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12) maxlags(3)

* ardl heating HDD SNSR price_l3m, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12) maxlags(3)
* ardl heating HDD SNSR price_l3m if sample_pre_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12) maxlags(3)
* ardl heating HDD SNSR price_l3m if sample_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12) maxlags(3)

* ardl baseload HDD SNSR price_l3m, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12) maxlags(3)
* ardl baseload HDD SNSR price_l3m if sample_pre_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12) maxlags(3)
* ardl baseload HDD SNSR price_l3m if sample_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12) maxlags(3)


***************************** PREDICTED CONSUMPTION ****************************

* Begin by running a model where we predict the coefficients on the historical data (i.e., before the crisis), and then use the estimated coefficients to predict consumption over the crisis. Then, use the Δ between actual and predicted consumption to measure savings.
ardl RDS HDD SNSR price_l3m if sample_pre_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12) lags(1 0 0 0)

estimates store my_ardl_model

forecast create myforecast, replace
forecast estimates my_ardl_model
forecast solve, prefix(predicted_) begin(744)

gen savings = predicted_RDS - RDS

preserve

keep if time >= 743

tsline RDS predicted_RDS, legend(row(1) pos(6) label(1 "Actual Consumption") label(2 "Predicted Consumption")) name(g1, replace) xtitle("") ytick(0(1000)6000) ylabel(0(1000)6000) 
graph export g1.png, as(png) replace 

tsline savings, ytick(-300(100)900) ylabel(-300(100)900) name(g2, replace) xtitle("") ytitle("")  
graph export g2.png, as(png) replace 

restore

graph drop _all





************************************ SAVINGS ***********************************

preserve

* Extract year and month from the monthly date variable.
gen year = yofd(dofm(time))
gen month = month(dofm(time))

* Create a semester indicator (1 = Jan-Jun, 2 = Jul-Dec).
gen semester = cond(month <= 6, 1, 2)

* Generate a year-semester indicator
gen ym_semester = year + (semester - 1) * 0.5

* Now assign the EUROSTAT €/GJ price based on year and semester.
gen price_EUROSTAT = .
replace price_EUROSTAT = 27.3987 if ym_semester == 2022
replace price_EUROSTAT = 36.3797 if ym_semester == 2022.5
replace price_EUROSTAT = 27.2429 if ym_semester == 2023
replace price_EUROSTAT = 37.4158 if ym_semester == 2023.5
replace price_EUROSTAT = 31.6726 if ym_semester == 2024
replace price_EUROSTAT = 44.0677 if ym_semester == 2024.5
replace price_EUROSTAT = 34.4437 if ym_semester == 2025

keep if time >= 743

collapse (sum) savings (max) price_EUROSTAT, by(ym_semester)

gen savings_GJ = savings * 1000000 * 0.0380619

gen bil_euro_savings = savings_GJ * price_EUROSTAT  / 1000000000

restore

graph drop _all



******************************* ELASTICITY - RDS *******************************

preserve 

* Initialize variables for elasticity and CIs.
gen eta_t = .
gen upper_eta = . 
gen lower_eta = .

gen year = year(Date)

* Generate an ID for the loops.
gen ID = _n

bysort year: egen mean_RDS = mean(RDS)

bysort year: egen mean_price_l3m = mean(price_l3m)

forvalues i = 120(1)168 {
	
	qui ardl RDS HDD SNSR price_l3m, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12) ec lags(1 1 0 2)

	qui scalar mean_price_t = mean_price_l3m[`i']
	
	qui scalar mean_RDS_t = mean_RDS[`i']
	
	qui lincom -[price_l3m * (mean_price_t / mean_RDS_t)]
	
	qui replace eta_t = r(estimate) if ID == `i'

	qui replace upper_eta = r(ub) if ID == `i'

	qui replace lower_eta = r(lb) if ID == `i'
		
}

replace eta_t = 0 if missing(eta_t)
replace upper_eta = 0 if missing(upper_eta)
replace lower_eta = 0 if missing(lower_eta)

drop ID

collapse (mean) eta_t upper_eta lower_eta, by(year)

tsset year, yearly 

twoway (tsline eta_t) (rcap lower_eta upper_eta year, lcolor(black)), xtick(2012(1)2025) xlabel(2012(1)2025) legend(rows(1) position(6) label(1 "Average Yearly Elasticity") label(2 "95% CI")) ytick(0(0.1)0.5) ylabel(0(0.1)0.5)
graph export RDS_Yearly_Elasticity_95_CI.png, as(png) replace 

restore

graph drop _all

*********************** ELASTICITY - HEATING & BASELOAD ************************

* Average yearly elasticities WITH 95% CIs.
preserve

gen year = year(Date)

* Initialize variables for elasticity and CIs.
gen eta_t_heat = .
gen upper_eta_heat = . 
gen lower_eta_heat = .
gen eta_t_base = .
gen upper_eta_base = . 
gen lower_eta_base = .

* Generate an ID for the loops.
gen ID = _n

bysort year: egen mean_heating = mean(heating)

bysort year: egen mean_baseload = mean(baseload)

bysort year: egen mean_price_l3m = mean(price_l3m)

forvalues i = 120(1)168 {
	
	qui ardl heating HDD SNSR price_l3m, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12) ec lags(1 2 0 1)

	qui scalar mean_price_t = mean_price_l3m[`i']
	
	qui scalar mean_heating_t = mean_heating[`i']
	
	qui lincom -[price_l3m * (mean_price_t / mean_heating_t)]
	
	qui replace eta_t_heat = r(estimate) if ID == `i'

	qui replace upper_eta_heat = r(ub) if ID == `i'

	qui replace lower_eta_heat = r(lb) if ID == `i'
		
}


forvalues i = 120(1)168 {
	
	qui ardl baseload HDD SNSR price_l3m, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12) ec lags(1 0 0 0)

	qui scalar mean_price_t = mean_price_l3m[`i']
	
	qui scalar mean_baseload_t = mean_baseload[`i']
	
	qui lincom -[price_l3m * (mean_price_t / mean_baseload_t)]
	
	qui replace eta_t_base = r(estimate) if ID == `i'

	qui replace upper_eta_base = r(ub) if ID == `i'

	qui replace lower_eta_base = r(lb) if ID == `i'
		
}

drop ID

replace eta_t_heat = 0 if missing(eta_t_heat)
replace upper_eta_heat = 0 if missing(upper_eta_heat)
replace lower_eta_heat = 0 if missing(lower_eta_heat)
replace eta_t_base = 0 if missing(eta_t_base)
replace upper_eta_base = 0 if missing(upper_eta_base)
replace lower_eta_base = 0 if missing(lower_eta_base)


collapse (mean) eta_t_heat eta_t_base upper_eta_heat upper_eta_base lower_eta_heat lower_eta_base, by(year)

tsset year, yearly 

twoway (tsline eta_t_heat) (rcap lower_eta_heat upper_eta_heat year, lcolor(black)) (tsline eta_t_base) (rcap lower_eta_base upper_eta_base year, lcolor(black)), ytick(0(0.1)0.5) ylabel(0(0.1)0.5) xtick(2012(1)2024) xlabel(2012(1)2024) legend(rows(1) position(6) order(1 3 2) label(1 "Avg. Yearly Elasticity (Heating)") label(3 "Avg. Yearly Elasticity (Baseload)") label(2 "95% CIs"))
graph export Base_Heat_Yearly_Elasticity_95_CI.png, as(png) replace 

restore

graph drop _all




***************************** ELASTICITY - Q TILDE *****************************

qui ardl RDS HDD SNSR price_l3m, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12) lags(1 1 0 2)

matrix coefficients = e(b)

gen b_RDS_L1 = coefficients[1,1]
gen b_HDD = coefficients[1,2]
gen b_HDD_L1 = coefficients[1,3]
gen b_SNSR = coefficients[1,4]
gen b_Month_2 = coefficients[1,8]
gen b_Month_3 = coefficients[1,9]
gen b_Month_4 = coefficients[1,10]
gen b_Month_5 = coefficients[1,11]
gen b_Month_6 = coefficients[1,12]
gen b_Month_7 = coefficients[1,13]
gen b_Month_8 = coefficients[1,14]
gen b_Month_9 = coefficients[1,15]
gen b_Month_10 = coefficients[1,16]
gen b_Month_11 = coefficients[1,17]
gen b_Month_12 = coefficients[1,18]
gen b_TimeTrend = coefficients[1,19]

gen Q_tilde = RDS - (b_RDS_L1 * L1.RDS + b_HDD * HDD + b_HDD_L1 * L1.HDD + b_SNSR * SNSR + ///
				     b_Month_2 * Month_2 + b_Month_3 * Month_3 + b_Month_4 * Month_4 + b_Month_5 * Month_5 + b_Month_6 * Month_6 + ///
					 b_Month_7 * Month_7 + b_Month_8 * Month_8 + b_Month_9 * Month_9 + b_Month_10 * Month_10 + b_Month_11 * Month_11 + ///
					 b_Month_12 * Month_12 + b_TimeTrend * TimeTrend)
			
replace Q_tilde = 0 if Date < td("01/12/2021")

tsline Q_tilde, ttick(2012m1 2014m1 2016m1 2018m1 2020m1 2022m1 2024m1 2026m1) tlabel(2012m1 "Jan 2012" 2014m1 "Jan 2014" 2016m1 "Jan 2016" 2018m1 "Jan 2018" 2020m1 "Jan 2020"  2022m1 "Jan 2022" 2024m1 "Jan 2024" 2026m1 "Jan 2026") xtitle("Date") ytitle("")
graph export Q_tilde_monthly_model.jpg, as(jpg) replace 

drop b_RDS_L1 b_HDD b_HDD_L1 b_SNSR b_Month_2 b_Month_3 b_Month_4 b_Month_5 b_Month_6 b_Month_7 b_Month_8 b_Month_9 b_Month_10 b_Month_11 b_Month_12 b_TimeTrend



preserve

gen year = year(Date)

* Initialize variables for elasticity and CIs.
gen eta_t_Q = .
gen upper_eta_Q = . 
gen lower_eta_Q = .


* Generate an ID for the loops.
gen ID = _n

bysort year: egen mean_Q_tilde = mean(Q_tilde)

bysort year: egen mean_price_l3m = mean(price_l3m)

forvalues i = 120(1)168 {
	
	qui ardl RDS HDD SNSR price_l3m, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12) ec lags(1 1 0 2)

	qui scalar mean_price_t = mean_price_l3m[`i']
	
	qui scalar mean_Q_t = mean_Q_tilde[`i']
	
	qui lincom -[price_l3m * (mean_price_t / mean_Q_t)]
	
	qui replace eta_t_Q = r(estimate) if ID == `i'

	qui replace upper_eta_Q = r(ub) if ID == `i'

	qui replace lower_eta_Q = r(lb) if ID == `i'
		
}

drop ID

replace eta_t_Q = 0 if missing(eta_t_Q)
replace upper_eta_Q = 0 if missing(upper_eta_Q)
replace lower_eta_Q = 0 if missing(lower_eta_Q)

collapse (mean) eta_t_Q upper_eta_Q lower_eta_Q, by(year)

tsset year, yearly

twoway (tsline eta_t_Q) (rcap lower_eta_Q upper_eta_Q year, lcolor(black)), ytick(0(0.1)1) ylabel(0(0.1)1) xtick(2012(1)2024) xlabel(2012(1)2024) legend(rows(1) position(6) order(1 2) label(1 "Avg. Yearly Elasticity") label(2 "95% CIs")) name(Q)
graph export Elasticity_95_CI_Q_tilde_monthly_model.png, as(png) replace 

restore

graph drop _all

}
