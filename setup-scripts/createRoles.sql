Drop Role "PMP_ROLE";
CREATE ROLE "PMP_ROLE";
GRANT "CONNECT" TO "PMP_ROLE";
GRANT "DBA" TO "PMP_ROLE";

Drop Role "CARRENT_USER_ROLE";
CREATE ROLE "CARRENT_USER_ROLE" ;
GRANT "CONNECT" TO "CARRENT_USER_ROLE" ;
GRANT "DBA" TO "CARRENT_USER_ROLE" ;

Drop Role "PNU_SUBJECT_OWNER";
CREATE ROLE "PNU_SUBJECT_OWNER" ;
GRANT "CONNECT" TO "PNU_SUBJECT_OWNER" ;
GRANT "DBA" TO "PNU_SUBJECT_OWNER" ;

Drop Role "ASOKKARY";
CREATE ROLE "ASOKKARY" ;
GRANT "CONNECT" TO "ASOKKARY" ;
GRANT "DBA" TO "ASOKKARY" ;
