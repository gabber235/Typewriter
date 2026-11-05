DEFINE TABLE OVERWRITE commit_submission SCHEMAFULL TYPE NORMAL PERMISSIONS NONE;
DEFINE FIELD OVERWRITE request ON commit_submission TYPE string;
DEFINE FIELD OVERWRITE committed_at ON commit_submission TYPE datetime DEFAULT time::now();
DEFINE INDEX OVERWRITE commit_submission_age ON commit_submission FIELDS committed_at;
