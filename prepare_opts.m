function opts = prepare_opts(dataset)

% Adjustable paths
% Select the disk location of your datasets
opts.path_datasets = 'watts/datasets';
% Path where the generated files will be saved
opts.pathData = '~/workspace_new/data/watts_LBP';
% Select the dataset
if nargin < 1
    dataset = 'SVT';
end
opts.dataset = dataset;

% Adding all the necessary libraries and paths
addpath('watts');
addpath('watts/util/');
if ~exist('util/bin','dir')
    mkdir('util/bin');
end
addpath('watts/util/bin');
addpath('watts/util/io');
if ~exist('calib_c','file')
    mex -output util/bin/calib_c -O -largeArrayDims util/calib_c.c
end
if ~exist('computeStats_c','file')
    mex -output util/bin/computeStats_c -O -largeArrayDims  CFLAGS="\$CFLAGS -std=c99" util/computeStats_c.c
end
if ~exist('phoc_mex','file')
    mex -output util/bin/phoc_mex -O -largeArrayDims util/phoc_mex.cpp
end
if ~exist('levenshtein_c','file')
    mex -output util/bin/levenshtein_c -O -largeArrayDims util/levenshtein_c.c
end
if ~exist('watts/util/vlfeat-0.9.18/toolbox/mex','dir')
    if isunix
        cd 'watts/util/vlfeat-0.9.18/';
        mexloc = fullfile(matlabroot,'bin/mex');
        % This is necessary to include support to OpenMP in Mavericks+XCode5
        % gcc4.2 can be installed from MacPorts
        %if strcmpi(computer,'MACI64')
        %   system(sprintf('make MEX=%s CC=/opt/local/bin/gcc-apple-4.2',mexloc));
        %else
        system(sprintf('make MEX=%s',mexloc));
        %end
        cd ../..;
    else
        run('watts/util/vlfeat-0.9.18/toolbox/vl_compile');
    end
end


run('watts/util/vlfeat-0.9.18/toolbox/vl_setup')

% Set random seed to default
rng('default');

opts.pathDataset = sprintf('%s/%s/',opts.path_datasets,opts.dataset);
opts.pathImages = sprintf('%s/%s/images/',opts.path_datasets,opts.dataset);
opts.pathDocuments = sprintf('%s/%s/documents/',opts.path_datasets,opts.dataset);
opts.pathQueries = sprintf('%s/%s/queries/',opts.path_datasets,opts.dataset);

% Options FV features
opts.numWordsTrainGMM = 100;
opts.SIFTDIM = 128;
opts.PCADIM = 62;
% for LBP
opts.LBPSZ =8;
opts.radius =1;
opts.samples =8;
opts.numSpatialX = 1;
opts.numSpatialY = 1;
opts.G = 16;
opts.phowOpts = {'Verbose', false, 'Step', 3, 'FloatDescriptors', true, 'sizes',[2,4,6,8,10,12]} ;
opts.doMinibox = 0;
opts.minH = -1;
opts.maxH = 99999;
opts.fold = -1;

% Options PHOC attributes
opts.levels = [2 3 4 5];
opts.levelsB = [2];
opts.numBigrams = 50;
fid = fopen('watts/data/bigrams.txt','r');
bgrams = textscan(fid,'%s');
fclose(fid);
opts.bgrams = bgrams{1}(1:opts.numBigrams);
opts.unigrams = 'abcdefghijklmnopqrstuvwxyz';
opts.digits='0123456789';
opts.considerDigits = 1;

% Options learning models
opts.bagging = 1;
opts.cluster = 0;
opts.sgdparams.eta0s = single([1]);
opts.sgdparams.lbds = single([1e-3,1e-4,1e-5]);
opts.sgdparams.betas = int32([32,64,80]);
opts.sgdparams.bias_multipliers = single([1]);
opts.sgdparams.epochs = 75;
opts.sgdparams.eval_freq = 2;
opts.sgdparams.t = 0;
opts.sgdparams.weightPos = 1;
opts.sgdparams.weightNeg = 1;

% Options embedding
opts.RemoveStopWords = 0;
opts.TestFV = 1;
opts.TestDirect = 0;

opts.TestPlatts = 0;
opts.Platts.verbose = 0;

opts.TestRegress = 0;
opts.Reg.Reg = [1e-1,1e-2,1e-3,1e-4];
opts.Reg.verbose = 1;

opts.TestCCA = 1;
opts.CCA.Dims = [96];
opts.CCA.Reg = [1e-4,1e-5,1e-6];
opts.CCA.verbose = 0;

opts.TestKCCA = 1;
opts.KCCA.M = [2500];
opts.KCCA.G = [40];
opts.KCCA.Dims = [160];
opts.KCCA.Reg = [1e-5];
opts.KCCA.verbose = 1;

opts.evalRecog = 0;
opts.TestHybrid = 1;

% Specific dataset options
if strcmp(opts.dataset,'GW')
    opts.fold = 1;
    opts.minH = 80;
    opts.maxH = 80;
elseif strcmp(opts.dataset,'IAM')
    opts.PCADIM = 30;
    opts.RemoveStopWords = 1;
    opts.swFile = 'data/swIAM.txt';
    opts.minH = 80;
    opts.maxH = 80;
elseif strcmp(opts.dataset,'IIIT5K')
    opts.minH = 80;
    opts.maxH = 80;
    opts.doMinibox = 0;
elseif strcmp(opts.dataset,'SVT')
    opts.minH = 80;
    opts.maxH = 80;
    opts.doMinibox = 0;
elseif strcmp(opts.dataset,'ICDAR11')
    opts.minH = 80;
    opts.maxH = 80;
    opts.doMinibox = 0;
elseif strcmp(opts.dataset,'ICDAR03')
    opts.minH = 80;
    opts.maxH = 80;
    opts.doMinibox = 0;
elseif strcmp(opts.dataset,'LP')
    opts.minH = 80;
    opts.maxH = 80;
    opts.doMinibox = 0;
elseif strcmp(opts.dataset,'LP')
    opts.minH = 80;
    opts.maxH = 80;
    opts.doMinibox = 0;

end

%opts.FVdim = (opts.PCADIM+2)*opts.numSpatialX*opts.numSpatialY*opts.G*2;
opts.FVdim = opts.LBPSZ*opts.numSpatialX*opts.numSpatialY*opts.G;

if opts.evalRecog || opts.TestHybrid
    opts.TestKCCA = 1;
end

% Tags
tagminH = '';
if opts.minH > -1 || opts.maxH < 99999
    tagminH = sprintf('_minH%d_maxH%d',opts.minH, opts.maxH);
end
tagFold = '';
if opts.fold > -1
    tagFold = sprintf('_fold%d',opts.fold);
end
tagPCA = sprintf('_PCA%d',opts.PCADIM);
tagGMM = sprintf('_GMM%dx%dx%dx%d%s',opts.G,opts.numSpatialY,opts.numSpatialX,opts.PCADIM+2,tagminH);
tagBMM = sprintf('_BMM%dx%dx%dx%d%s',opts.G,opts.numSpatialY,opts.numSpatialX,opts.PCADIM+2,tagminH);
tagLevels = ['_l' strrep(strrep(strrep(mat2str(opts.levels),' ',''),'[',''),']','')];
tagLevelsB = ['_lb' strrep(strrep(strrep(mat2str(opts.levelsB),' ',''),'[',''),']','')];
tagNumB = sprintf('_nb%d',opts.numBigrams);
if opts.bagging
    tagBagging = '_bagging';
else
    tagBagging = '_noBagging';
end
tagFeats = '_FV';

opts.tagPHOC = sprintf('_PHOCs%s%s%s',tagLevels,tagLevelsB,tagNumB);
opts.tagFeatures = sprintf('%s%s%s%s',tagFeats,tagPCA,tagGMM,tagFold);

% Paths and files
opts.pathFiles = sprintf('%s/files',opts.pathData);
if ~exist(opts.pathData,'dir')
    mkdir(opts.pathData);
end
opts.dataFolder = sprintf('%s/%s%s%s',opts.pathFiles,opts.dataset,opts.tagPHOC,opts.tagFeatures);
if ~exist(opts.dataFolder,'dir')
    mkdir(opts.dataFolder);
end
opts.fileData = sprintf('%s/%s_data.mat',opts.pathFiles,opts.dataset);
opts.fileImages = sprintf('%s/%s_images%s.bin',opts.pathFiles,opts.dataset,tagminH);
opts.fileWriters = sprintf('%s/%s_writers.mat',opts.pathFiles,opts.dataset);
opts.fileGMM = sprintf('%s/%s%s.bin',opts.dataFolder,opts.dataset,tagGMM);
opts.fileBMM = sprintf('%s/%s%s.mat',opts.dataFolder,opts.dataset,tagBMM);
opts.filePCA = sprintf('%s/%s%s.bin',opts.dataFolder,opts.dataset,tagPCA);
opts.filePHOCs = sprintf('%s/%s%s.bin',opts.dataFolder,opts.dataset,opts.tagPHOC);
opts.fileFeatures = sprintf('%s/%s%s.bin',opts.dataFolder,opts.dataset,opts.tagFeatures);
opts.fileAttModels = sprintf('%s/%s_attModels%s%s%s.bin',opts.dataFolder,opts.dataset,opts.tagPHOC,opts.tagFeatures,tagBagging);
opts.fileAttRepresTr = sprintf('%s/%s_attRepresTr%s%s%s.bin',opts.dataFolder,opts.dataset,opts.tagPHOC,opts.tagFeatures,tagBagging);
opts.fileAttRepresVal = sprintf('%s/%s_attRepresVal%s%s%s.bin',opts.dataFolder,opts.dataset,opts.tagPHOC,opts.tagFeatures,tagBagging);
opts.fileAttRepresTe = sprintf('%s/%s_attRepresTe%s%s%s.bin',opts.dataFolder,opts.dataset,opts.tagPHOC,opts.tagFeatures,tagBagging);
opts.folderModels = sprintf('%s/models%s/',opts.dataFolder,tagBagging);
opts.modelsLog = sprintf('%s/learning.log',opts.folderModels);
if ~exist(opts.folderModels,'dir')
    mkdir(opts.folderModels);
end
opts.fileSets = sprintf('watts/data/%s_words_indexes_sets%s.mat',opts.dataset,tagFold);
opts.fileLexicon = sprintf('%s/%s_lexicon%s.mat',opts.pathFiles,opts.dataset,opts.tagPHOC);
end
