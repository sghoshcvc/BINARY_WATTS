function extract_features(opts)
disp('* Extracting FV features *');
% Extracts the FV representation for every image in the dataset

if  ~exist(opts.fileFeatures,'file')
      
    if ~exist(opts.fileBMM,'file')
        toc = readImagesToc(opts.fileImages);
        % Computes GMM and PCA models
        idxTrainGMM = sort(randperm(length(toc),opts.numWordsTrainGMM));
        [fid,msg] = fopen(opts.fileImages, 'r');
        getImage = @(x) readImage(fid,toc,x);
        images = arrayfun(getImage, idxTrainGMM', 'uniformoutput', false);
        fclose(fid);
        BMM = compute_BMM_models(opts,images);
        %writeBMM(BMM,opts.fileBMM);
        save(opts.fileBMM,'BMM');
        %writePCA(PCA, opts.filePCA); % for now not using PCA
        clear images;
    end
        
    extract_FV_Binary(opts);
    
end

end
