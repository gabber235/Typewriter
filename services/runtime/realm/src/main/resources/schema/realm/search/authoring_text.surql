DEFINE ANALYZER OVERWRITE authoring_text TOKENIZERS class FILTERS lowercase;
DEFINE ANALYZER OVERWRITE authoring_prefix TOKENIZERS class FILTERS lowercase, edgengram(1, 16);
DEFINE ANALYZER OVERWRITE authoring_approximate TOKENIZERS class FILTERS lowercase, ngram(2, 4);
