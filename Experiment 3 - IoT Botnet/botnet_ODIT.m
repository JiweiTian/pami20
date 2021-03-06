clear variables; clc; close all;
load botnet_baseline_ODIT.mat;

% Online Detection -- FAP calculations
alpha = 0.2;
thresh_index = round((length(baseline_distances))*(1-alpha));
sorted_arr = sort(baseline_distances);
odit_thresh = sorted_arr(thresh_index);
h = ([0.001:0.1:1 1e2 1e3 1e4 1e5 1e6 1e7 1e8 1e9 1e10 1e11 1e12 1e13 1e14 1e15 1e16 1e17:5e16:2e18])';
no_trials = 1e3; % number of trials
sum_fap = zeros(length(h),1);

for i = 1:no_trials
    i
    alarm_flag = zeros(length(h),1);
    g = 0; % initial decision stat
    t = 1;
    while (alarm_flag(length(h)) == 0)    
       index_rand = randi(N,1);
       datum_t = X(index_rand,:); % random nominal data point
       tmp_dist = zeros(num,1);
       for j = 1:num
           datum_j = C(j,:);
           dist_tj = norm(datum_t-datum_j,2);  % Euclidean distance
           tmp_dist(j) = dist_tj;
       end
       sort_dist = sort(tmp_dist,'ascend');
       sum_kNN = sum(sort_dist(1:k));
       g = max(0, g + sum_kNN - odit_thresh);
       sum_fap = sum_fap + t*(g >= h).*(alarm_flag == 0);
       alarm_flag = alarm_flag + (g >= h).*(alarm_flag == 0);
       % time update   
       t = t + 1;
    end
end
mean_fap = sum_fap/no_trials;
false_positive_rate = 1./mean_fap;  % false alarm rate = reciprocal of the mean false period

% Attack Data
load junk_thermostat.mat;
X_3 = junk_thermostat;
rr = length(X_3);

% Online Detection -- ADD calculations
%tau = 1; % attack launch time (corresponds to the worst-case scenerio)
sum_add = zeros(length(h),1);
num_trials = 2e3;
max_tolerable_delay1 = 10;
cnt_detected1 = zeros(length(h),1);  % compute how many times detected within the delay bound, for each threshold level
max_tolerable_delay2 = 15;
cnt_detected2 = zeros(length(h),1);
max_tolerable_delay3 = 20;
cnt_detected3 = zeros(length(h),1);
max_tolerable_delay4 = 25;
cnt_detected4 = zeros(length(h),1);

for i = 1:num_trials
    i
    alarm_flag = zeros(length(h),1);
    g = 0; % initial decision stat
    t = 0;
    while (alarm_flag(length(h)) == 0 || t <= max_tolerable_delay4)  
       index_rand = randi(rr,1);
       datum_t = X_3(index_rand,:);     % random anomalous data point
       tmp_dist = zeros(num,1);
       for j = 1:num
           datum_j = C(j,:);
           dist_tj = norm(datum_t-datum_j,2);  % Euclidean distance
           tmp_dist(j) = dist_tj;
       end
       sort_dist = sort(tmp_dist,'ascend');
       sum_kNN = sum(sort_dist(1:k));
       g = max(0, g + sum_kNN - odit_thresh);
       sum_add = sum_add + t*(g >= h).*(alarm_flag == 0);
       alarm_flag = alarm_flag + (g >= h).*(alarm_flag == 0);
       
       if (t == max_tolerable_delay1)
           cnt_detected1 = cnt_detected1 + alarm_flag; % increment detection cases if detected within the given delay bound
       end
       
       if (t == max_tolerable_delay2)
           cnt_detected2 = cnt_detected2 + alarm_flag; 
       end
       
       if (t == max_tolerable_delay3)
           cnt_detected3 = cnt_detected3 + alarm_flag; 
       end
       
       if (t == max_tolerable_delay4)
           cnt_detected4 = cnt_detected4 + alarm_flag; 
       end
       
       % time update
       t = t + 1;
    end
end
mean_add = sum_add/num_trials;
recall_10 = cnt_detected1/num_trials;   % true positive rate when the max. allowed detection delay is 10
recall_15 = cnt_detected2/num_trials;   % true positive rate when the max. allowed detection delay is 15
recall_20 = cnt_detected3/num_trials;
recall_25 = cnt_detected4/num_trials;

save('botnet_ODIT_results');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Online Attack Detection -- Sample Path
tmax = 250; % max time
tau = 200; % attack launch time
decision_stat = zeros(tmax,1);
t = 1;
g = 0;
while (t <= tmax)
    if (t < tau)
       index_rand = randi(N,1);
       datum_t = X(index_rand,:); % random nominal data point
       tmp_dist = zeros(num,1);
       for j = 1:num
           datum_j = C(j,:);
           dist_tj = norm(datum_t-datum_j,2);  % Euclidean distance
           tmp_dist(j) = dist_tj;
       end
       sort_dist = sort(tmp_dist,'ascend');
       sum_kNN = sum(sort_dist(1:k));
       g = max(0, g + sum_kNN - odit_thresh);
    elseif (t >= tau)
       index_rand = randi(rr,1);
       datum_t = X_3(index_rand,:);     % random anomalous data point
       tmp_dist = zeros(num,1);
       for j = 1:num
           datum_j = C(j,:);
           dist_tj = norm(datum_t-datum_j,2);  % Euclidean distance
           tmp_dist(j) = dist_tj;
       end
       sort_dist = sort(tmp_dist,'ascend');
       sum_kNN = sum(sort_dist(1:k));
       g = max(0, g + sum_kNN - odit_thresh);
    end    
    decision_stat(t) = g;
    t = t + 1;
end

plot(decision_stat, 'linewidth',2);
hold on;
xlabel('$t$','interpreter','latex','fontsize',14);
ylabel('$g_t$','interpreter','latex','fontsize',14);




