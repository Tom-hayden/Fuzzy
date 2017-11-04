% This file implements a MLP classifier.
% Mario Gini, Tom Hayden

% define the training and test batch size.
trainSize = 20000;
testSize  = 10000;
testEnd   = min(trainSize+testSize+1,60000);



% aquire, preprocess and augment the data.
dataAquisition();
dataPreProcessing(cifarData, trainSize);
onlyFlip = true;
[cifarDataMirrored, cifarLabelsMirrored] = dataAugmentation(cifarData(1:trainSize,:),cifarLabels(1:trainSize,:),trainSize,onlyFlip);


%[cifarData2, mu, invMat, whMat] = whiten(cifarData);

% train and test the MLP classifier.
% [net, sucessRateTraining] = networkTraining(50,cifarData(1:trainSize,:),cifarLabels(1:trainSize,:));
% sucessRateTesting = networkTesting(net, cifarData(trainSize+1:testEnd,:), cifarLabels(trainSize+1:testEnd,:));

% [net, sucessRateTraining] = networkTraining(50,cifarDataMirrored,cifarLabelsMirrored);
% sucessRateTesting = networkTesting(net, cifarData(trainSize+1:testEnd,:), cifarLabels(trainSize+1:testEnd,:));

for i = 1:10

 [net, sucessRateTraining] = networkTraining(10*i,cifarData(1:trainSize,:),cifarLabels(1:trainSize,:));
 sucessRateTesting = networkTesting(net, cifarData(trainSize+1:testEnd,:), cifarLabels(trainSize+1:testEnd,:));
 
 [net, sucessRateTraining] = networkTraining(10*i,cifarDataMirrored,cifarLabelsMirrored);
 sucessRateTesting = networkTesting(net, cifarData(trainSize+1:testEnd,:), cifarLabels(trainSize+1:testEnd,:));

end

function dataAquisition()
% loads all the cifar data into the workspace for the MLP network. The last
% 10000 rows of the array represent the test data.
%
% Outputs: - cifarData 60000*3072 array containing the image information.
%          - cifarLabels 60000*10 array containging the image labels.

addpath(genpath('..\cifar-10-batches-mat'));
cifarData = zeros(60000,3072);
cifarLabels = zeros(60000,10);

% load training data
for i = 1:5
    load(strcat('data_batch_',num2str(i)));
    for j = 1 : 10000
        cifarData((i-1)*10000+j,:) = data(j,:);
        labelItem = labels(j,1);
        cifarLabels((i-1)*10000+j,labelItem+1) = 1;
    end
end

% load test data
load('test_batch');
for j = 1 : 10000
    cifarData(50000+j,:) = data(j,:);
    labelItem = labels(j,1);
    cifarLabels(50000+j,labelItem+1) = 1;
end

% save variables in workspace
assignin('base','cifarData',cifarData);
assignin('base','cifarLabels',cifarLabels);
end

function dataPreProcessing(cifarData, trainSize)
% normalizes the data and subtracts the mean per pixel based on the
% training batch size.

% normalization to range [0,1]
cifarData = 1/255*cifarData;

% subtract mean per pixel. The mean is only calculated over the training
% data.
cifarData= cifarData - mean(cifarData(1:trainSize,:));

% save modified data in workspace
assignin('base','cifarData',cifarData);
end

function [Xwh, mu, invMat, whMat] = whiten(X,epsilon)
%function [X,mu,invMat] = whiten(X,epsilon)
%
% ZCA whitening of a data matrix (make the covariance matrix an identity matrix)
%
% WARNING
% This form of whitening performs poorly if the number of dimensions are
% much greater than the number of instances
%
%
% INPUT
% X: rows are the instances, columns are the features
% epsilon: small number to compensate for nearly 0 eigenvalue [DEFAULT =
% 0.0001]
%
% OUTPUT
% Xwh: whitened data, rows are instances, columns are features
% mu: mean of each feature of the orginal data
% invMat: the inverse data whitening matrix
% whMat: the whitening matrix
%
% EXAMPLE
%
% X = rand(100,20); % 100 instance with 20 features
%
% figure;
% imagesc(cov(X)); colorbar; title('original covariance matrix');
%
% [Xwh, mu, invMat, whMat] = whiten(X,0.0001);
%
% figure;
% imagesc(cov(Xwh)); colorbar; title('whitened covariance matrix');
%
% Xwh2 = (X-repmat(mean(X), size(X,1),1))*whMat;
% figure;
% plot(sum((Xwh-Xwh2).^2),'-rx'); title('reconstructed whitening error (should be 0)');
%
% Xrec = Xwh*invMat + repmat(mu, size(X,1),1);
% figure;
% plot(sum((X-Xrec).^2),'-rx'); ylim([-1,1]); title('reconstructed data error (should be zero)');
%
% Author: Colorado Reed colorado-reed@uiowa.edu


if ~exist('epsilon','var')
    epsilon = 0.0001;
end

mu = mean(X);
X = bsxfun(@minus, X, mu);
A = X'*X;
[V,D,notused] = svd(A);
whMat = sqrt(size(X,1)-1)*V*sqrtm(inv(D + eye(size(D))*epsilon))*V';
Xwh = X*whMat;
invMat = pinv(whMat);

end

function [augData, augLabels] = dataAugmentation(dataSet,dataLabels,trainSize,onlyFlip)
% augments the data by flipping and rotating it.

imgData = uint8(zeros(32,32,3,trainSize));

for i = 1:trainSize
    imgData(:,:,:,i) = rot90(reshape(dataSet(i,:),[32,32,3]),3);
end

% increase dataLabels to 8 times the size.
if(onlyFlip)
    augLabels = [dataLabels; dataLabels];
else
    augLabels = dataLabels;
    for i = 1:7
        augLabels = [augLabels; dataLabels];
    end
end

% Allocate memory and assign first two batches to original and flipped
% around y-axis version of data.
if(onlyFlip)
    augData = zeros(2*trainSize,3072);
    imgDataFlipped = flip(imgData,2);
    rotDataFirst = zeros(2*trainSize,3072);
    for j = 1:trainSize
        rotDataFirst(j,:) = reshape(rot90(imgData(:,:,:,j),-3),[1,3072]);
        rotDataFirst(trainSize+j,:) = reshape(rot90(imgDataFlipped(:,:,:,j),-3),[1,3072]);
    end
    augData(1:2*trainSize,:) = rotDataFirst;
else
    augData = zeros(8*trainSize,3072);
    imgDataFlipped = flip(imgData,2);
    rotDataFirst = zeros(2*trainSize,3072);
    for j = 1:trainSize
        rotDataFirst(j,:) = reshape(rot90(imgData(:,:,:,j),-3),[1,3072]);
        rotDataFirst(trainSize+j,:) = reshape(rot90(imgDataFlipped(:,:,:,j),-3),[1,3072]);
    end
    augData(1:2*trainSize,:) = rotDataFirst;
    for i = 1:3
        rotDataSecond = zeros(2*trainSize,3072);
        imgDataRot = rot90(imgData,i);
        imgDataFlippedRot = rot90(imgDataFlipped,i);
    for j = 1:trainSize
        rotDataSecond(j,:) = reshape(rot90(imgDataRot(:,:,:,j),-3),[1,3072]);
        rotDataSecond(trainSize+j,:) = reshape(rot90(imgDataFlippedRot(:,:,:,j),-3),[1,3072]);
    end
    entry = 2*trainSize+2*(i-1)*trainSize;
    augData(entry+1:entry+2*trainSize,:) = rotDataSecond;
end
end
end

function dispImg(Img)
% simple function to show an image.
figure()
image = uint8(reshape(Img,[32,32,3]));
image = rot90(image,3);
imshow(image,'Border','tight','InitialMagnification',600);

end

function [net,sucessRateTraining] = networkTraining(numberNeurons,data,target)
% defines and trains a MLP classifier.

x = data';
t = target';

trainFcn = 'trainscg';

net.trainFcn = 'traingdx';

% Create a Pattern Recognition Network
hiddenLayerSize = [100 numberNeurons];
net = patternnet(hiddenLayerSize, trainFcn);


% Setup Division of Data for Training, Validation, Testing. No need for
% test data since we test the model separately after training.
net.divideParam.trainRatio = 80/100;
net.divideParam.valRatio = 20/100;
net.divideParam.testRatio = 0/100;

% Performance function
net.performFcn = 'crossentropy';

% Train the Network

[net,tr] = train(net,x,t);

% Test the Network
y = net(x);
e = gsubtract(t,y);
%  performance = perform(net,t,y)
tind = vec2ind(t);
yind = vec2ind(y);
percentErrors = sum(tind ~= yind)/numel(tind);

sucessRateTraining = 1- percentErrors

end

function sucessRateTesting = networkTesting(net,data,target)
% tests the network on the test batch.
x = data';
t = target';
y = net(x);
e = gsubtract(t,y);
tind = vec2ind(t);
yind = vec2ind(y);
percentErrors = sum(tind ~= yind)/numel(tind);
sucessRateTesting = 1- percentErrors

end





% View the Network
% view(net)

% Plots
% Uncomment these lines to enable various plots.
%figure, plotperform(tr)
%figure, plottrainstate(tr)
%figure, ploterrhist(e)
%figure, plotconfusion(t,y)
%figure, plotroc(t,y)