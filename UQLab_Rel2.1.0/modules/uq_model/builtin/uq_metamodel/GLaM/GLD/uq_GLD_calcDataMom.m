function mom = uq_GLD_calcDataMom(data,method)
if strcmp(method,'MM')
    mom=[mean(data),var(data),skewness(data),kurtosis(data)];
elseif strcmp(method,'RM')
    data_sort=sort(data,1,'ascend');
    n_data=size(data,1);
    %25 percentile
    v=0.25;
    r=floor((n_data+1)*v);
    k=(n_data+1)*v-floor((n_data+1)*v);
    pt_25=data_sort(r)+k*(data_sort(r+1)-data_sort(r));
    %50 percentile
    v=0.5;
    r=floor((n_data+1)*v);
    k=(n_data+1)*v-floor((n_data+1)*v);
    pt_50=data_sort(r)+k*(data_sort(r+1)-data_sort(r));
    %75 percentile
    v=0.75;
    r=floor((n_data+1)*v);
    k=(n_data+1)*v-floor((n_data+1)*v);
    pt_75=data_sort(r)+k*(data_sort(r+1)-data_sort(r));
    %12.5 percentile
    v=1/8;
    r=floor((n_data+1)*v);
    k=(n_data+1)*v-floor((n_data+1)*v);
    pt_125=data_sort(r)+k*(data_sort(r+1)-data_sort(r));
    %37.5 percentile
    v=3/8;
    r=floor((n_data+1)*v);
    k=(n_data+1)*v-floor((n_data+1)*v);
    pt_375=data_sort(r)+k*(data_sort(r+1)-data_sort(r));
    %62.5 percentile
    v=5/8;
    r=floor((n_data+1)*v);
    k=(n_data+1)*v-floor((n_data+1)*v);
    pt_625=data_sort(r)+k*(data_sort(r+1)-data_sort(r));
    %87.5 percentile
    v=7/8;
    r=floor((n_data+1)*v);
    k=(n_data+1)*v-floor((n_data+1)*v);
    pt_875=data_sort(r)+k*(data_sort(r+1)-data_sort(r));
    
    rm1 = pt_50;
    rm2 = pt_75 - pt_25;
    rm3 = (pt_75+pt_25-2*pt_50)/rm2;
    rm4 = (pt_875 - pt_625 + pt_375 - pt_125)/rm2;
    mom=[rm1,rm2,rm3,rm4];
end

