% script to test cellXploreDR


load('mockData.mat');
genFakeMovies;
data.movies = movies;

% playMovie(movies{1})
cellXploreDR('data', data, []);
