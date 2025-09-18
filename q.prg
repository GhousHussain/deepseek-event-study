'=========================================================
' Event Study – Bootstrap CAR p-values (AAPL, MSFT, NVDA)
' Market model; windows [-1,+1] and [-5,+5] around 2025/01/27
'=========================================================

' ---------- 0) Clean up ----------
delete(noerr) est win_pm1 win_pm5
delete(noerr) t evmask evcount m_pm1 m_pm5
smpl @all

' ---------- 1) Estimation window ----------
sample est 2023/07/03 2025/01/03

' ---------- 2) Estimate market model on estimation window ----------
smpl est
equation eq_aapl.ls r_aapl c r_mkt
equation eq_msft.ls r_msft c r_mkt
equation eq_nvda.ls r_nvda c r_mkt
smpl @all

' Abnormal returns
series ar_aapl = r_aapl - (eq_aapl.@coefs(1) + eq_aapl.@coefs(2)*r_mkt)
series ar_msft = r_msft - (eq_msft.@coefs(1) + eq_msft.@coefs(2)*r_mkt)
series ar_nvda = r_nvda - (eq_nvda.@coefs(1) + eq_nvda.@coefs(2)*r_mkt)

' ---------- 3) Robust index-based event masks ----------
series t       = @cumsum(1)                           ' 1..T index
series evmask  = (date<=@dateval("2025/01/27"))       ' 1 if date <= event
series evcount = @cumsum(evmask)                      ' 1..K over those dates
scalar ev      = @max(evcount)                        ' event trading-day index

series m_pm1 = (t>=ev-1)*(t<=ev+1)                    ' [-1,+1]
series m_pm5 = (t>=ev-5)*(t<=ev+5)                    ' [-5,+5]

' ---------- 4) Bootstrap settings ----------
!reps   = 1000
rndseed 12345

' ---------- 5) Loop over firms ----------
for %f aapl msft nvda

  ' Estimation pool (valid ARs only)
  smpl est
  series est_ar_{%f} = ar_{%f}
  series idx_{%f}    = @cumsum(1-@isna(est_ar_{%f}))   ' 1..N valid ARs
  scalar n_est_{%f}  = @max(idx_{%f})
  smpl @all

  ' Actual CARs via temp product series
  series __prod1_{%f}  = ar_{%f}*m_pm1
  series __prod5_{%f}  = ar_{%f}*m_pm5
  scalar car_{%f}_pm1  = @sum(__prod1_{%f})
  scalar car_{%f}_pm5  = @sum(__prod5_{%f})
  delete(noerr) __prod1_{%f} __prod5_{%f}

  ' Window lengths (valid obs inside masks)
  series __valid1_{%f} = m_pm1*(1-@isna(ar_{%f}))
  series __valid5_{%f} = m_pm5*(1-@isna(ar_{%f}))
  scalar n_pm1_{%f}    = @sum(__valid1_{%f})
  scalar n_pm5_{%f}    = @sum(__valid5_{%f})
  delete(noerr) __valid1_{%f} __valid5_{%f}

  ' Defaults
  scalar p1s_{%f}_pm1 = na
  scalar p2s_{%f}_pm1 = na
  scalar p1s_{%f}_pm5 = na
  scalar p2s_{%f}_pm5 = na

  ' Bootstrap only if we have data
  if (n_est_{%f}>0) and (n_pm1_{%f}>0) and (n_pm5_{%f}>0) then

     scalar cnt1_pm1_{%f} = 0
     scalar cnt2_pm1_{%f} = 0
     scalar cnt1_pm5_{%f} = 0
     scalar cnt2_pm5_{%f} = 0

     for !i = 1 to !reps

        ' Draw CAR for [-1,+1]
        scalar s1 = 0
        for !j = 1 to n_pm1_{%f}
           scalar k1   = @floor(@rnd*n_est_{%f}) + 1
           scalar draw = @sum(est_ar_{%f} * (idx_{%f}=k1))
           s1 = s1 + draw
        next

        ' Draw CAR for [-5,+5]
        scalar s5 = 0
        for !j = 1 to n_pm5_{%f}
           scalar k5   = @floor(@rnd*n_est_{%f}) + 1
           scalar draw = @sum(est_ar_{%f} * (idx_{%f}=k5))
           s5 = s5 + draw
        next

        ' Count exceedances
        if @isna(car_{%f}_pm1)=0 then
           if s1 >  car_{%f}_pm1 then cnt1_pm1_{%f} = cnt1_pm1_{%f} + 1
           endif
           if @abs(s1) >= @abs(car_{%f}_pm1) then cnt2_pm1_{%f} = cnt2_pm1_{%f} + 1
           endif
        endif
        if @isna(car_{%f}_pm5)=0 then
           if s5 >  car_{%f}_pm5 then cnt1_pm5_{%f} = cnt1_pm5_{%f} + 1
           endif
           if @abs(s5) >= @abs(car_{%f}_pm5) then cnt2_pm5_{%f} = cnt2_pm5_{%f} + 1
           endif
        endif

     next

     ' p-values
     scalar p1s_{%f}_pm1 = cnt1_pm1_{%f} / !reps
     scalar p2s_{%f}_pm1 = cnt2_pm1_{%f} / !reps
     scalar p1s_{%f}_pm5 = cnt1_pm5_{%f} / !reps
     scalar p2s_{%f}_pm5 = cnt2_pm5_{%f} / !reps

  endif

next

smpl @all

' ---------- 6) SHOW all results (copy from the output window to Excel) ----------
show car_aapl_pm1 car_aapl_pm5 p1s_aapl_pm1 p2s_aapl_pm1 p1s_aapl_pm5 p2s_aapl_pm5
show car_msft_pm1 car_msft_pm5 p1s_msft_pm1 p2s_msft_pm1 p1s_msft_pm5 p2s_msft_pm5
show car_nvda_pm1 car_nvda_pm5 p1s_nvda_pm1 p2s_nvda_pm1 p1s_nvda_pm5 p2s_nvda_pm5

' ---------- 7) Optional: export as a minimal CSV (no table object needed) ----------
' This creates a 1-observation page with the scalars as series and saves it.
' (If your build doesn’t support this, skip it and copy from the SHOW output.)
'
' delete(noerr) results_pg
' pagedown(results_pg) 1
' series a_car_pm1 = car_aapl_pm1
' series a_car_pm5 = car_aapl_pm5
' series a_p1_pm1  = p1s_aapl_pm1
' series a_p2_pm1  = p2s_aapl_pm1
' series a_p1_pm5  = p1s_aapl_pm5
' series a_p2_pm5  = p2s_aapl_pm5
'
' series m_car_pm1 = car_msft_pm1
' series m_car_pm5 = car_msft_pm5
' series m_p1_pm1  = p1s_msft_pm1
' series m_p2_pm1  = p2s_msft_pm1
' series m_p1_pm5  = p1s_msft_pm5
' series m_p2_pm5  = p2s_msft_pm5
'
' series n_car_pm1 = car_nvda_pm1
' series n_car_pm5 = car_nvda_pm5
' series n_p1_pm1  = p1s_nvda_pm1
' series n_p2_pm1  = p2s_nvda_pm1
' series n_p1_pm5  = p1s_nvda_pm5
' series n_p2_pm5  = p2s_nvda_pm5
'
' wfsave(type=csv) "E:\GHOUS_FINAL_RESEARCH\bootstrap_summary.csv"


'=========================
' EXPORT RESULTS TO CSV (no tables/matrices)
'=========================

' 1) Create a new unstructured page with 3 rows (AAPL, MSFT, NVDA)
delete(noerr) results_page
pagecreate(page=results_page) unstructured 3
pageselect results_page

' 2) Create columns
alpha firm
series car_pm1  car_pm5  p1s_pm1  p2s_pm1  p1s_pm5  p2s_pm5

' 3) Fill rows
smpl 1 1
firm     = "AAPL"
car_pm1  = @movav(@series(car_aapl_pm1),1)   ' assign scalar to a series
car_pm5  = @movav(@series(car_aapl_pm5),1)
p1s_pm1  = @movav(@series(p1s_aapl_pm1),1)
p2s_pm1  = @movav(@series(p2s_aapl_pm1),1)
p1s_pm5  = @movav(@series(p1s_aapl_pm5),1)
p2s_pm5  = @movav(@series(p2s_aapl_pm5),1)

smpl 2 2
firm     = "MSFT"
car_pm1  = @movav(@series(car_msft_pm1),1)
car_pm5  = @movav(@series(car_msft_pm5),1)
p1s_pm1  = @movav(@series(p1s_msft_pm1),1)
p2s_pm1  = @movav(@series(p2s_msft_pm1),1)
p1s_pm5  = @movav(@series(p1s_msft_pm5),1)
p2s_pm5  = @movav(@series(p2s_msft_pm5),1)

smpl 3 3
firm     = "NVDA"
car_pm1  = @movav(@series(car_nvda_pm1),1)
car_pm5  = @movav(@series(car_nvda_pm5),1)
p1s_pm1  = @movav(@series(p1s_nvda_pm1),1)
p2s_pm1  = @movav(@series(p2s_nvda_pm1),1)
p1s_pm5  = @movav(@series(p1s_nvda_pm5),1)
p2s_pm5  = @movav(@series(p2s_nvda_pm5),1)

' 4) Save to CSV (choose a path you can write to)
pagesave(t=csv) "bootstrap_results.csv"
' Example with absolute folder (ensure it exists):
' pagesave(t=csv) "E:\GHOUS_FINAL_RESEARCH\bootstrap_results.csv"

' 5) Return to original page (optional)
pageselect 1

