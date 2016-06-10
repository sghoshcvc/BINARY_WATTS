function data =load_imageClef(opts)
bbFile = 'bboxs_train_for_query-by-example.txt';
fileQueries=[opts.pathQueries bbFile];
fid =fopen(fileQueries,'r');
bbInfo = textscan(fid,'%s%s%s');
%fname = bbInfo{1};
%bbs = bbInfo{2};
%gttext = bbInfo{3};
x = strfind(bbInfo{2},'x');
fn = strfind(bbInfo{2},'+');

% for j=1:length(bbInfo{1})
%     x1(j) = str2num(bbInfo{2}{j}(1:x{j}-1));
%     x2(j) = str2num(bbInfo{2}{j}(x{j}+1:fn{j,1}-1));
%     x3(j) = str2num(bbInfo{2}{j}(fn{j}(1)+1:fn{j}(2)-1));
%     x4(j) = str2num(bbInfo{2}{j}(fn{j}(2)+1:end));
%     
% end
% pos = [x3',x4',x1',x2']; %x,y,wd,ht

nWords = length(bbInfo{1});
margin=0;
pathIm = '';
%pathImages = 'pages_train/';

for j=1:nWords
    words(j).pathIm = [opts.pathImages bbInfo{1}{j} '.jpg'];
    x1 = str2num(bbInfo{2}{j}(1:x{j}-1));
    x2 = str2num(bbInfo{2}{j}(x{j}+1:fn{j,1}-1));
    x3 = str2num(bbInfo{2}{j}(fn{j}(1)+1:fn{j}(2)-1));
    x4 = str2num(bbInfo{2}{j}(fn{j}(2)+1:end));
    loc = [x3 x4 x1 x2];
    
    %words(j).origLoc = loc;
    
    loc = [loc(1)-margin loc(2)+margin loc(3)-margin loc(4)+margin];
    if ~strcmp(words(j).pathIm,pathIm)
        imDoc = imread(words(j).pathIm);
        if ndims(imDoc)>2
            imDoc = rgb2gray(imDoc);
        end
        pathIm = words(j).pathIm;
    end
    [H,W] = size(imDoc);
    x1 = max(loc(1),1); x2 = min(loc(3),W)+x1-1;
    y1 = max(loc(2),1); y2 = min(loc(4),H)+y1-1;
    im = imDoc(y1:y2,x1:x2);
    words(j).loc = [x1 x2 y1 y2];
    [words(j).H,words(j).W,numC] = size(im);
    words(j).gttext = bbInfo{3}{j};
    
    words(j).docId = bbInfo{1}{j};
end

newClass = 1;
words(1).class = [];
classes = containers.Map();
idxClasses = {};
names = {};

for i=1:length(words)
    gttext = lower(words(i).gttext);
    % Determine the class of the query given the GT text
    if isKey(classes, gttext)
        class = classes(gttext);
    else
        class = newClass;
        newClass = newClass+1;
        classes(gttext) = class;
        idxClasses{class} = int32([]);
        names{class} = gttext;
    end
    idxClasses{class} = [idxClasses{class} i];
    words(i).class = class;
end
newClass = 1;
words(1).docIdx = [];
docClasses = containers.Map();
docIdxClasses = {};
docnames = {};

for i=1:length(words)
    dname = lower(words(i).docId);
    % Determine the class of the query given the GT text
    if isKey(docClasses,dname )
        class = docClasses(dname);
    else
        class = newClass;
        newClass = newClass+1;
        docClasses(dname) = class;
        docIdxClasses{class} = int32([]);
        docnames{class} = dname;
    end
    docIdxClasses{class} = [docIdxClasses{class} i];
    words(i).docIdx = class;
end

%% Output
data.words = words;
data.classes = classes;
data.idxClasses = idxClasses;
data.names = names;
data.docClasses = docClasses;
data.docidxClasses = docIdxClasses;
data.docnames=docnames;

end