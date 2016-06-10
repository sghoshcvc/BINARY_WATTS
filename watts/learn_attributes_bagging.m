function [att_models,attFeatsTr] = learn_attributes_bagging(opts,data)
% Learns models using several folds of the training data.
% Also produces the scores of the training samples with an unbiased model.
% For each training sample, we get its score using a model constructed as
% the average of all models that did not use that particular training
% sample for training. This is done online.

% Set params. eta, lbd, beta and bias_multiplier can receive multiple
% values that will be crossvalidated for map.
params = opts.sgdparams;
%params.weightsTr = data.weightsTr;

feats = data.feats_training;
phocs = data.phocs_training;

[numAtt,numSamples] = size(phocs);
dimFeats = size(feats,1);

% Output encoded
attFeatsTr = single(zeros(numAtt,numSamples));
att_models = struct('W',[],'B',[],'numPosSamples',[]);

% For each attribute
for idxAtt = 1:numAtt
    [model, encodedTr] = learn_att(idxAtt,feats, phocs,dimFeats, numSamples, opts, params);
    att_models(idxAtt) = model;
    attFeatsTr(idxAtt,:) = encodedTr;
end
end


function [model, attFeatsBag] = learn_att(idxAtt,feats, phocs,dimFeats, numSamples, opts, params)
    fileModel = sprintf('%smodel_%.3d.mat',opts.folderModels,idxAtt);
    if ~exist(fileModel,'file')
        % Separate positives and negatives
        idxPos = find(phocs(idxAtt,:) >= 0.48);
        idxNeg = find(phocs(idxAtt,:) < 0.48);
        nPos = length(idxPos);
        nNeg = length(idxNeg);
        
        % If too few positives, discard attribute :(
        if nPos < 2 || nNeg < 2
            fprintf('Model for attribute %d discarded. Not enough data\n',idxAtt);
            f=fopen(opts.modelsLog,'a');
            fprintf(f,'Model for attribute %d discarded. Not enough data\n',idxAtt);
            fclose(f);
            model.W = single(zeros(dimFeats,1));
            model.B = 0;
            model.numPosSamples = 0;
            attFeatsBag = single(zeros(1, numSamples));
            save(fileModel,'model','attFeatsBag');
            return;
        end
        
        % Prepare the output classifier and bias
        W=single(zeros(dimFeats,1));
        B = 0;
        attFeatsBag = single(zeros(1, numSamples));
        % Keep counts of how many updates, global and per sample
        Np = zeros(numSamples,1);
        N = 0;
        numPosSamples = 0;
        
        % Do two passes through the data so every sample gets scored at least twice
        numPasses = 2;
        numIters = 2;
        for cpass = 1:numPasses
            % Randomize data
            idxPos = idxPos(randperm(nPos));
            idxNeg = idxNeg(randperm(nNeg));
            % Get number of samples per group. Since we use floor and we
            % enforce at least two positive samples, there should always be
            % at least one sample in train and val for the positives. The
            % negatives should be populated enough.
            nTrainPos = floor(0.8*nPos);
            nValPos = nPos - nTrainPos;
            nTrainNeg = floor(0.8*nNeg);
            nValNeg = nNeg - nTrainNeg;
            
            % for each iteration
            for it=1:numIters
                % Get the first nTrain as train and the rest as val                
                idxTrain = [   idxPos(1:nTrainPos) idxNeg(1:nTrainNeg)];
                idxVal = [idxPos(nTrainPos+1:end) idxNeg(nTrainNeg+1:end)];
                % Get actual data
                featsTrain = feats(:,idxTrain);
                phocsTrain = phocs(:,idxTrain);
                featsVal = feats(:,idxVal);
                phocsVal = phocs(:,idxVal);
                labelsTrain = int32(phocsTrain(idxAtt,:)~=0);
                labelsVal = int32(phocsVal(idxAtt,:)~=0);                
                %weightsTrain = params.weightsTr(idxTrain);
                
                numPosSamples = numPosSamples + nTrainPos;
                % Learn model
                tic;
                %modelAtt = sgdsvm_train_cv_mex(featsTrain,labelsTrain,featsVal,labelsVal,params);
               % modelAtt = cvSVM(featsTrain,labelsTrain,featsVal,labelsVal,weightsTrain,  params);
                modelAtt = cvSVM(featsTrain,labelsTrain,featsVal,labelsVal,  params);
                t=toc;
                fprintf('Model for attribute %d it %d pass %d (%.2f map) learned in %.0f seconds using %d positive samples\n',idxAtt, it,cpass, modelAtt.info.acc, t, nTrainPos);
                f=fopen(opts.modelsLog,'a');
                fprintf(f,'Model for attribute %d it %d pass %d (%.2f map) learned in %.0f seconds using %d positive samples\n',idxAtt,it,cpass, modelAtt.info.acc, t, nTrainPos);
                fclose(f);
                
                % Update things. Update the scores of the samples not used for
                % training, as well as the global model.
                N = N+1;
                Np(idxVal) = Np(idxVal)+1;
                sc = modelAtt.W'*featsVal;
                attFeatsBag(idxVal) = attFeatsBag(idxVal) + sc;
                W = W + modelAtt.W;
                B = B + modelAtt.B;
                
                % shift the idx to get new samples next iter
                idxPos=circshift(idxPos, [0,nValPos]);
                idxNeg=circshift(idxNeg, [0,nValNeg]);
                
            end            
        end                        
        
        % Average and save
        model.W = W;
        model.B = B;
        model.numPosSamples = 0;
        if N~=0
            model.W = model.W/N;
            model.B = model.B/N;
            attFeatsBag = attFeatsBag ./ Np';
            model.numPosSamples = ceil(numPosSamples / N);
        end
        
        save(fileModel,'model','attFeatsBag');
        
    else
        fprintf('\nAttribute %d already computed. Loaded.\n',idxAtt);
        load(fileModel); % Contains the variables to return.
    end
end


function map = modelMap(scores, labels)
[s,idx] = sort(scores, 'descend');
labelsSort = single(labels(idx)); 
acc = cumsum(labelsSort).*labelsSort;
N = sum(labelsSort);
map = sum(single(acc)./(1:length(labels)))/N;
end

function model = cvSVM(featsTrain, labelsTrain, featsVal, labelsVal,  params) 
        bestmap = 0;
        bestlbd = 0;
        W = [];
        B = [];
        for lbd=params.lbds
           % if any(weightsTrain~=1)
              %  [Wv,Bv,info, scores] = vl_svmtrain(featsTrain, double(2*labelsTrain-1), double(lbd),'BiasMultiplier', 0.1, 'weights', double(weightsTrain));
          %  else
                [Wv,Bv,info, scores] = vl_svmtrain(featsTrain, double(2*labelsTrain-1), double(lbd),'BiasMultiplier', 0.1);
           % end
            cmap = modelMap(Wv'*featsVal, labelsVal);
            if cmap > bestmap
                bestmap = cmap;
                bestlbd = double(lbd);
                W = Wv;
                B = Bv;
            end
        end
        model.W = W;
        model.B = B;
        model.info.acc = 100*bestmap;
end
