function FV = CalFisherVectorBMM(descrs,BMM)

%% Generate the Fisher Vector
% Create the G_uid
%D = 9; 
[num_of_points, D] = size(descrs);
%x = reshape(Xval,[],D);
%[T, ~]= size(x_td);
num_cluster = BMM.NumComponents;
x = descrs;
w = BMM.ComponentProportion;                        % weights
u = BMM.Means;                                      % means

for point = 1:num_of_points
    % gamma_t = zeros(num_cluster,1);
    % clus = bmm.cluster(x(point,:));
    gamma_t = BMM.pdf(x(point,:));
    G_u = zeros(num_cluster, D);
    for i=1:num_cluster
        for d=1:D
            G = 0;
            for t=1
                G = G + (gamma_t(i)*(((-1)^(x(t,d)))/((1-u(i,d))^(x(t,d)))));
            end
            G_u(i,d) = G/t;

        end
    end
    %fisher_vector{point} = G_u; 
end

% Create the F_uid
% first_term is the first summation term in the equation(14)
% second_term is the second summation term in the equation(14)
for i=1:num_cluster
    for d=1:D
        first_term = 0;
        second_term = 0;
        for j=1:num_cluster
            first_term = first_term + (w(j)*u(j,d));
            second_term = second_term + + (w(j)*(1-u(j,d)));
        end
        F_u(i,d) = t * w(i) * ((first_term/u(i,d)^2)+(second_term/(1-u(i,d))^2));
    end
end

FV = G_u./F_u.^(.5);
FV = reshape(FV,[],1);

%% Power normalisation of the fisher vector 

%fisher_vector_powerNorm = sign(fisher_vector).* (fisher_vector^(0.5));

%% L2 normalisation
%fisher_vector_powerNorm_L2 = norm(fisher_vector_powerNorm);