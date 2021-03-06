function [gaborP,mdctP, harmP,diracL] = bookplot( book, channel, bwfactor )

% Usage :
%   bookplot(book)
%   bookplot(book,chan)
%   bookplot(book,chan,bwfactor)
%
% Synopsis :
%   Plots a Matching Pursuit book in the current axes
%
% Detailed description :
%   * bookplot(book) plots the default channel (first channel).
%   * bookplot(book,chan) plots the channel number chan of a MPTK book structure in the current 
%     axes. If book is a string, it is understood as a filename and the book is read from the 
%     corresponding file. Books can be read separately using the bookread utility.
%   * bookplot(book,chan,bwfactor) allows to specify the bandwidths of the atoms, 
%     calculated as: bw = ( fs / (atom.length(channel)/2) ) / bwfactor; where fs is 
%     the signal sample frequency. When omitted, bwfactor defaults to 2.
%
% Notes :
%    The patches delimit the support of the atoms. Their color is proportional to the atom’s
% amplitudes, mapped to the current colormap and the current axis.

%%
%% Authors:
%% Sacha Krstulovic & Remi Gribonval
%% Contributors:
%% Kamil Adiloglu 
%% Copyright (C) 2005 IRISA                                              
%%
%% This script is part of the Matching Pursuit Library package,
%% distributed under the General Public License.
%%
%% SVN log:
%%   $Author: broy $
%%   $Date: 2007-01-15 18:00:30 +0100 (Mon, 15 Jan 2007) $
%%   $Revision: 783 $
%%

if ischar(book),
   disp('Loading the book...');
   book = bookread( book );
   disp('Done.');
end;

if nargin < 2,
   channel = 1;
end;

if channel > book.numChans,
   error('Book has %d channels. Can''t display channel number %d.', ...
	       channel, book.numChans );
end;

if nargin < 3,
   bwfactor = 2;
end;

l = book.numSamples;
fs = book.sampleRate;

gaborX = [];
gaborY = [];
gaborZ = [];
gaborC = [];
mdctX = [];
mdctY = [];
mdctZ = [];
mdctC = [];
harmX = [];
harmY = [];
harmZ = [];
harmC = [];
diracX = [];
diracY = [];
diracZ = [];

for i = 1:book.numAtoms,
  atom = extract_atom_from_book(book,i);
    switch atom.type,

	   case 'gabor',
		p = atom.pos(channel)/fs;
		l = atom.len(channel)/fs;
		bw2 = ( fs / (atom.len(channel)/2) ) / bwfactor;
		A = atom.amp(channel); A = 20*log10(A);
		f = fs*atom.freq;
		c = fs*fs*atom.chirp;

		pv = [p;p;p+l;p+l];
		fv = [f-bw2; f+bw2; f+bw2+c*l; f-bw2+c*l];
		av = [A; A; A; A];

		gaborX = [gaborX,pv];
		gaborY = [gaborY,fv];
		gaborZ = [gaborZ,av];
		gaborC = [gaborC,A];      

	   case 'mdct',
		pos = atom.pos(channel) / fs;
		len = atom.len(channel) / fs;
		bw2 = ( fs / (atom.len(channel)/2) ) / bwfactor;
		
        amp = atom.amp(channel);
        amp = 20*log10(abs(amp));
        
		freq = fs * atom.freq;
		c = 0;

		pos_v = [pos; pos; pos + len; pos + len];
		freq_v = [freq - bw2; freq + bw2; freq + bw2 + c * len; freq - bw2 + c * len];
		amp_v = [amp; amp; amp; amp];

		mdctX = [mdctX, pos_v];
		mdctY = [mdctY, freq_v];
		mdctZ = [mdctZ, amp_v];
		mdctC = [mdctC, amp];
        
	   case 'harmonic',
		p = atom.pos(channel)/fs;
		l = atom.len(channel)/fs;
		bw2 = ( fs / (atom.len(channel)/2 + 1) ) / bwfactor;
		A = atom.amp(channel);
		f = atom.freq;
		c = fs*fs*atom.chirp;

		pv = repmat([p;p;p+l;p+l],1,atom.numPartials);

		fv = fs*atom.freq*atom.harmonicity';
		dfv = c*l;
		fvup = fv+bw2;
		fvdown = fv-bw2;
		fv = [fvup;fvdown;fvdown+dfv;fvup+dfv];

		cv = A*atom.partialAmpStorage(:,channel)';
		cv = 20*log10(cv);

		av = [cv;cv;cv;cv];

		harmX = [harmX,pv];
		harmY = [harmY,fv];
		harmZ = [harmZ,av];
		harmC = [harmC,cv];

	   case 'dirac',
		p = atom.pos(channel)/fs;
		A = atom.amp(channel); A = 20*log10(A);
		diracX = [diracX;NaN;p;p];
		diracY = [diracY;NaN;0;fs/2];
		diracZ = [diracZ;NaN;A;A];

	   % Unknown atom type
	   otherwise,
		error( [ '[' atom.type '] is an unknown atom type.'] );
    end;

end;

gaborP = patch( gaborX, gaborY, gaborZ, gaborC, 'edgecol', 'none' );
mdctP = patch( mdctX, mdctY, mdctZ, mdctC, 'edgecol', 'none' );
harmP  = patch( harmX,  harmY,  harmZ,  harmC,  'edgecol', 'none' );
diracL = line( diracX, diracY, diracZ, 'color', 'k' );


function atom=extract_atom_from_book(book,i)
  switch book.format
    case '0.0' % The format of book structures as read by old bookread scripts 
      atom = book.atom{i};
    case '0.1' % The format of book structures as read by mptk4matlab with MPTK 0.5.6 
      % Get the type
      typeindex = book.index(2,i);
      atom.type = book.atom(typeindex).type; 
      % Get the index of the atom within atom of its type
      atomNumberInAtomsOfType = book.index(3,i);
      % Get the list of fields
      fields = fieldnames(book.atom(typeindex).params);
      % Copy the fields
      for j=1:length(fields)
	field = fields{j};
	atom.(field) = book.atom(typeindex).params.(field)(atomNumberInAtomsOfType,:);
      end
    otherwise
      error(['Unknown format ' book.format]);
  end


