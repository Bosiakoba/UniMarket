-- Ghana Universities & Campuses seed data for D1 (SQLite)
-- Run: wrangler d1 execute unimarket-db --remote --file=seed_universities.sql

CREATE TABLE IF NOT EXISTS universities (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  short_name TEXT,
  type TEXT,
  region TEXT,
  verified INTEGER DEFAULT 0
);

CREATE TABLE IF NOT EXISTS campuses (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  university_id TEXT NOT NULL REFERENCES universities(id),
  name TEXT NOT NULL,
  town TEXT,
  region TEXT,
  is_main INTEGER DEFAULT 0
);

INSERT INTO universities (id, name, short_name, type, region, verified) VALUES ('ug', 'University of Ghana', 'UG', 'public', 'Greater Accra', 1);
INSERT INTO universities (id, name, short_name, type, region, verified) VALUES ('knust', 'Kwame Nkrumah University of Science and Technology', 'KNUST', 'public', 'Ashanti', 1);
INSERT INTO universities (id, name, short_name, type, region, verified) VALUES ('ucc', 'University of Cape Coast', 'UCC', 'public', 'Central', 1);
INSERT INTO universities (id, name, short_name, type, region, verified) VALUES ('uew', 'University of Education, Winneba', 'UEW', 'public', 'Central', 1);
INSERT INTO universities (id, name, short_name, type, region, verified) VALUES ('uds', 'University for Development Studies', 'UDS', 'public', 'Northern', 1);
INSERT INTO universities (id, name, short_name, type, region, verified) VALUES ('cktutas', 'CK Tedam University of Technology and Applied Sciences', 'CKT-UTAS', 'public', 'Upper East', 0);
INSERT INTO universities (id, name, short_name, type, region, verified) VALUES ('sdd-ubids', 'Simon Diedong Dombo University of Business and Integrated Development Studies', 'SDD-UBIDS', 'public', 'Upper West', 0);
INSERT INTO universities (id, name, short_name, type, region, verified) VALUES ('aamusted', 'Akenten Appiah-Menka University of Skills Training and Entrepreneurial Development', 'AAMUSTED', 'public', 'Ashanti', 1);
INSERT INTO universities (id, name, short_name, type, region, verified) VALUES ('upsa', 'University of Professional Studies, Accra', 'UPSA', 'public', 'Greater Accra', 0);
INSERT INTO universities (id, name, short_name, type, region, verified) VALUES ('umat', 'University of Mines and Technology', 'UMaT', 'public', 'Western', 1);
INSERT INTO universities (id, name, short_name, type, region, verified) VALUES ('uhas', 'University of Health and Allied Sciences', 'UHAS', 'public', 'Volta', 1);
INSERT INTO universities (id, name, short_name, type, region, verified) VALUES ('uenr', 'University of Energy and Natural Resources', 'UENR', 'public', 'Bono', 1);
INSERT INTO universities (id, name, short_name, type, region, verified) VALUES ('uesd', 'University of Environment and Sustainable Development', 'UESD', 'public', 'Eastern', 0);
INSERT INTO universities (id, name, short_name, type, region, verified) VALUES ('gimpa', 'Ghana Institute of Management and Public Administration', 'GIMPA', 'public', 'Greater Accra', 0);
INSERT INTO universities (id, name, short_name, type, region, verified) VALUES ('gctu', 'Ghana Communication Technology University', 'GCTU', 'public', 'Greater Accra', 1);
INSERT INTO universities (id, name, short_name, type, region, verified) VALUES ('atu', 'Accra Technical University', 'ATU', 'public-technical', 'Greater Accra', 0);
INSERT INTO universities (id, name, short_name, type, region, verified) VALUES ('btu', 'Bolgatanga Technical University', 'BTU', 'public-technical', 'Upper East', 0);
INSERT INTO universities (id, name, short_name, type, region, verified) VALUES ('cctu', 'Cape Coast Technical University', 'CCTU', 'public-technical', 'Central', 0);
INSERT INTO universities (id, name, short_name, type, region, verified) VALUES ('kstu', 'Kumasi Technical University', 'KsTU', 'public-technical', 'Ashanti', 0);
INSERT INTO universities (id, name, short_name, type, region, verified) VALUES ('ktu', 'Koforidua Technical University', 'KTU', 'public-technical', 'Eastern', 0);
INSERT INTO universities (id, name, short_name, type, region, verified) VALUES ('tatu', 'Tamale Technical University', 'TaTU', 'public-technical', 'Northern', 0);
INSERT INTO universities (id, name, short_name, type, region, verified) VALUES ('htu', 'Ho Technical University', 'HTU', 'public-technical', 'Volta', 0);
INSERT INTO universities (id, name, short_name, type, region, verified) VALUES ('ttu', 'Takoradi Technical University', 'TTU', 'public-technical', 'Western', 0);
INSERT INTO universities (id, name, short_name, type, region, verified) VALUES ('stu', 'Sunyani Technical University', 'STU', 'public-technical', 'Bono', 0);
INSERT INTO universities (id, name, short_name, type, region, verified) VALUES ('wtu', 'Wa Technical University (formerly Wa Polytechnic)', 'WTU', 'public-technical', 'Upper West', 0);
INSERT INTO universities (id, name, short_name, type, region, verified) VALUES ('rmu', 'Regional Maritime University', 'RMU', 'public-regional', 'Greater Accra', 0);
INSERT INTO universities (id, name, short_name, type, region, verified) VALUES ('gij', 'Ghana Institute of Journalism', 'GIJ', 'public', 'Greater Accra', 0);
INSERT INTO universities (id, name, short_name, type, region, verified) VALUES ('gism', 'Ghana Institute of Surveying and Mapping', 'GISM', 'public', 'Greater Accra', 0);
INSERT INTO universities (id, name, short_name, type, region, verified) VALUES ('nafti', 'National Film and Television Institute', 'NAFTI', 'public', 'Greater Accra', 0);
INSERT INTO universities (id, name, short_name, type, region, verified) VALUES ('ashesi', 'Ashesi University', 'Ashesi', 'private', 'Eastern', 0);
INSERT INTO universities (id, name, short_name, type, region, verified) VALUES ('central', 'Central University', 'Central', 'private', 'Greater Accra', 1);
INSERT INTO universities (id, name, short_name, type, region, verified) VALUES ('vvu', 'Valley View University', 'VVU', 'private', 'Greater Accra', 0);
INSERT INTO universities (id, name, short_name, type, region, verified) VALUES ('pentvars', 'Pentecost University', 'PentVars', 'private', 'Greater Accra', 0);
INSERT INTO universities (id, name, short_name, type, region, verified) VALUES ('anu', 'All Nations University', 'ANU', 'private', 'Eastern', 0);
INSERT INTO universities (id, name, short_name, type, region, verified) VALUES ('presbyuc', 'Presbyterian University, Ghana', 'PUC', 'private', 'Eastern', 1);
INSERT INTO universities (id, name, short_name, type, region, verified) VALUES ('methodist', 'Methodist University Ghana', 'MUG', 'private', 'Greater Accra', 1);
INSERT INTO universities (id, name, short_name, type, region, verified) VALUES ('csuc', 'Christian Service University College', 'CSUC', 'private', 'Ashanti', 0);
INSERT INTO universities (id, name, short_name, type, region, verified) VALUES ('regent', 'Regent University College of Science and Technology', 'Regent', 'private', 'Greater Accra', 0);
INSERT INTO universities (id, name, short_name, type, region, verified) VALUES ('wiuc', 'Wisconsin International University College', 'WIUC', 'private', 'Greater Accra', 0);
INSERT INTO universities (id, name, short_name, type, region, verified) VALUES ('cug', 'Catholic University College of Ghana', 'CUG', 'private', 'Bono', 0);
INSERT INTO universities (id, name, short_name, type, region, verified) VALUES ('epuc', 'Evangelical Presbyterian University College', 'EPUC', 'private', 'Volta', 0);
INSERT INTO universities (id, name, short_name, type, region, verified) VALUES ('gbuc', 'Ghana Baptist University College', 'GBUC', 'private', 'Ashanti', 0);
INSERT INTO universities (id, name, short_name, type, region, verified) VALUES ('garden-city', 'Garden City University College', 'GCUC', 'private', 'Ashanti', 0);
INSERT INTO universities (id, name, short_name, type, region, verified) VALUES ('radford', 'Radford University College', 'Radford', 'private', 'Greater Accra', 1);
INSERT INTO universities (id, name, short_name, type, region, verified) VALUES ('spiritan', 'Spiritan University College', 'Spiritan', 'private', 'Ashanti', 0);
INSERT INTO universities (id, name, short_name, type, region, verified) VALUES ('data-link', 'Data Link Institute / University College', 'DLUC', 'private', 'Greater Accra', 0);
INSERT INTO universities (id, name, short_name, type, region, verified) VALUES ('mountcrest', 'Mountcrest University College', 'MCUC', 'private', 'Greater Accra', 0);
INSERT INTO universities (id, name, short_name, type, region, verified) VALUES ('ucaes', 'University College of Agriculture and Environmental Studies', 'UCAES', 'private', 'Eastern', 0);
INSERT INTO universities (id, name, short_name, type, region, verified) VALUES ('kings', 'Kings University College', 'KUC', 'private', 'Greater Accra', 0);
INSERT INTO universities (id, name, short_name, type, region, verified) VALUES ('maranatha', 'Maranatha University College', 'MUC', 'private', 'Greater Accra', 0);
INSERT INTO universities (id, name, short_name, type, region, verified) VALUES ('palm', 'Palm University College', 'PaUC', 'private', 'Greater Accra', 0);
INSERT INTO universities (id, name, short_name, type, region, verified) VALUES ('aucc', 'African University College of Communications', 'AUCC', 'private', 'Greater Accra', 0);
INSERT INTO universities (id, name, short_name, type, region, verified) VALUES ('ait', 'Accra Institute of Technology', 'AIT', 'private', 'Greater Accra', 0);
INSERT INTO universities (id, name, short_name, type, region, verified) VALUES ('iucg', 'Islamic University College, Ghana', 'IUCG', 'private', 'Greater Accra', 0);
INSERT INTO universities (id, name, short_name, type, region, verified) VALUES ('knutsford', 'Knutsford University College', 'Knutsford', 'private', 'Greater Accra', 0);
INSERT INTO universities (id, name, short_name, type, region, verified) VALUES ('lancaster-gh', 'Lancaster University Ghana', 'LUG', 'private', 'Greater Accra', 0);
INSERT INTO universities (id, name, short_name, type, region, verified) VALUES ('webster-gh', 'Webster University Ghana Campus', 'Webster', 'private', 'Greater Accra', 0);
INSERT INTO universities (id, name, short_name, type, region, verified) VALUES ('zenith', 'Zenith University College', 'ZUC', 'private', 'Greater Accra', 0);
INSERT INTO universities (id, name, short_name, type, region, verified) VALUES ('academic-city', 'Academic City University College', 'ACU', 'private', 'Greater Accra', 0);
INSERT INTO universities (id, name, short_name, type, region, verified) VALUES ('bluecrest', 'BlueCrest College / University College', 'BCUC', 'private', 'Greater Accra', 1);
INSERT INTO universities (id, name, short_name, type, region, verified) VALUES ('catholic-institute', 'Catholic Institute of Business and Technology', 'CIBT', 'private', 'Greater Accra', 0);
INSERT INTO universities (id, name, short_name, type, region, verified) VALUES ('anglican', 'Anglican University College of Technology', 'ANG.U.TECH', 'private', 'Bono East', 0);
INSERT INTO universities (id, name, short_name, type, region, verified) VALUES ('baptist', 'Ghana Baptist University College', 'GBUC2', 'private', 'Ashanti', 0);
INSERT INTO universities (id, name, short_name, type, region, verified) VALUES ('christ-apostolic', 'Christ Apostolic University College', 'CAUC', 'private', 'Ashanti', 0);
INSERT INTO universities (id, name, short_name, type, region, verified) VALUES ('dominion', 'Dominion University College', 'DUC', 'private', 'Greater Accra', 0);
INSERT INTO universities (id, name, short_name, type, region, verified) VALUES ('ghana-christian', 'Ghana Christian University College', 'GCU', 'private', 'Greater Accra', 0);
INSERT INTO universities (id, name, short_name, type, region, verified) VALUES ('marshalls', 'Marshalls University College', 'MUC2', 'private', 'Greater Accra', 0);
INSERT INTO universities (id, name, short_name, type, region, verified) VALUES ('perez', 'Perez University College', 'Perez', 'private', 'Central', 0);
INSERT INTO universities (id, name, short_name, type, region, verified) VALUES ('west-end', 'West End University College', 'WEUC', 'private', 'Greater Accra', 0);
INSERT INTO universities (id, name, short_name, type, region, verified) VALUES ('advanced-business', 'Advanced Business College', 'ABC', 'private', 'Greater Accra', 0);
INSERT INTO universities (id, name, short_name, type, region, verified) VALUES ('kaaf', 'KAAF University College', 'KAAF', 'private', 'Central', 0);
INSERT INTO universities (id, name, short_name, type, region, verified) VALUES ('heritage-christian', 'Heritage Christian University College', 'HCU', 'private', 'Greater Accra', 0);
INSERT INTO universities (id, name, short_name, type, region, verified) VALUES ('ensign', 'Ensign Global University College', 'Ensign', 'private', 'Eastern', 0);

INSERT INTO campuses (university_id, name, town, region, is_main) VALUES ('ug', 'Legon Campus', 'Legon, Accra', 'Greater Accra', 1);
INSERT INTO campuses (university_id, name, town, region, is_main) VALUES ('ug', 'Korle-Bu Campus (College of Health Sciences)', 'Korle-Bu, Accra', 'Greater Accra', 0);
INSERT INTO campuses (university_id, name, town, region, is_main) VALUES ('ug', 'Accra City Campus', 'Accra Central', 'Greater Accra', 0);
INSERT INTO campuses (university_id, name, town, region, is_main) VALUES ('ug', 'Kumasi City Campus', 'Adum, Kumasi', 'Ashanti', 0);
INSERT INTO campuses (university_id, name, town, region, is_main) VALUES ('ug', 'Takoradi City Campus', 'Chapel Hill, Takoradi', 'Western', 0);
INSERT INTO campuses (university_id, name, town, region, is_main) VALUES ('knust', 'Main Campus', 'Kumasi', 'Ashanti', 1);
INSERT INTO campuses (university_id, name, town, region, is_main) VALUES ('knust', 'Obuasi Campus', 'Obuasi', 'Ashanti', 0);
INSERT INTO campuses (university_id, name, town, region, is_main) VALUES ('ucc', 'South Campus (Old Site)', 'Cape Coast', 'Central', 1);
INSERT INTO campuses (university_id, name, town, region, is_main) VALUES ('ucc', 'North Campus (New Site)', 'Cape Coast', 'Central', 0);
INSERT INTO campuses (university_id, name, town, region, is_main) VALUES ('uew', 'Winneba North Campus (Central Administration)', 'Winneba', 'Central', 1);
INSERT INTO campuses (university_id, name, town, region, is_main) VALUES ('uew', 'Winneba Central Campus', 'Winneba', 'Central', 0);
INSERT INTO campuses (university_id, name, town, region, is_main) VALUES ('uew', 'Winneba South Campus', 'Winneba', 'Central', 0);
INSERT INTO campuses (university_id, name, town, region, is_main) VALUES ('uew', 'Ajumako Campus (College of Languages Education)', 'Ajumako', 'Central', 0);
INSERT INTO campuses (university_id, name, town, region, is_main) VALUES ('uds', 'Tamale Campus (Central Administration, Medicine)', 'Tamale', 'Northern', 1);
INSERT INTO campuses (university_id, name, town, region, is_main) VALUES ('uds', 'Nyankpala Campus (Agriculture, Engineering)', 'Nyankpala', 'Northern', 0);
INSERT INTO campuses (university_id, name, town, region, is_main) VALUES ('uds', 'Tamale City Campus (Business School, Graduate School)', 'Tamale', 'Northern', 0);
INSERT INTO campuses (university_id, name, town, region, is_main) VALUES ('cktutas', 'Navrongo Campus', 'Navrongo', 'Upper East', 1);
INSERT INTO campuses (university_id, name, town, region, is_main) VALUES ('sdd-ubids', 'Wa Campus', 'Wa', 'Upper West', 1);
INSERT INTO campuses (university_id, name, town, region, is_main) VALUES ('aamusted', 'Kumasi Campus (Main, former COLTEK, Tanoso)', 'Kumasi', 'Ashanti', 1);
INSERT INTO campuses (university_id, name, town, region, is_main) VALUES ('aamusted', 'Asante-Mampong Campus (former CAGRIC)', 'Asante-Mampong', 'Ashanti', 0);
INSERT INTO campuses (university_id, name, town, region, is_main) VALUES ('upsa', 'Main Campus', 'Legon, Accra', 'Greater Accra', 1);
INSERT INTO campuses (university_id, name, town, region, is_main) VALUES ('umat', 'Tarkwa Campus (Main)', 'Tarkwa', 'Western', 1);
INSERT INTO campuses (university_id, name, town, region, is_main) VALUES ('umat', 'Essikado Campus (School of Railways and Infrastructure Development, SRID)', 'Essikado, Sekondi-Takoradi', 'Western', 0);
INSERT INTO campuses (university_id, name, town, region, is_main) VALUES ('uhas', 'Ho Campus', 'Ho', 'Volta', 1);
INSERT INTO campuses (university_id, name, town, region, is_main) VALUES ('uhas', 'Hohoe Campus', 'Hohoe', 'Volta', 0);
INSERT INTO campuses (university_id, name, town, region, is_main) VALUES ('uenr', 'Sunyani Campus (Main)', 'Sunyani', 'Bono', 1);
INSERT INTO campuses (university_id, name, town, region, is_main) VALUES ('uenr', 'Nsoatre Campus (School of Engineering)', 'Nsoatre', 'Bono', 0);
INSERT INTO campuses (university_id, name, town, region, is_main) VALUES ('uenr', 'Dormaa Campus (School of Agriculture and Technology)', 'Dormaa Ahenkro', 'Bono', 0);
INSERT INTO campuses (university_id, name, town, region, is_main) VALUES ('uesd', 'Somanya Campus', 'Somanya', 'Eastern', 1);
INSERT INTO campuses (university_id, name, town, region, is_main) VALUES ('gimpa', 'Greenhill Campus', 'Legon, Accra', 'Greater Accra', 1);
INSERT INTO campuses (university_id, name, town, region, is_main) VALUES ('gctu', 'Tesano Campus (Main)', 'Tesano, Accra', 'Greater Accra', 1);
INSERT INTO campuses (university_id, name, town, region, is_main) VALUES ('gctu', 'Abeka Campus', 'Abeka, Accra', 'Greater Accra', 0);
INSERT INTO campuses (university_id, name, town, region, is_main) VALUES ('gctu', 'Kumasi Campus', 'Kumasi', 'Ashanti', 0);
INSERT INTO campuses (university_id, name, town, region, is_main) VALUES ('gctu', 'Nungua Learning Centre', 'Nungua, Accra', 'Greater Accra', 0);
INSERT INTO campuses (university_id, name, town, region, is_main) VALUES ('gctu', 'Ho Learning Centre', 'Ho', 'Volta', 0);
INSERT INTO campuses (university_id, name, town, region, is_main) VALUES ('gctu', 'Koforidua Learning Centre', 'Koforidua', 'Eastern', 0);
INSERT INTO campuses (university_id, name, town, region, is_main) VALUES ('gctu', 'Takoradi Learning Centre', 'Takoradi', 'Western', 0);
INSERT INTO campuses (university_id, name, town, region, is_main) VALUES ('atu', 'Main Campus', 'Accra', 'Greater Accra', 1);
INSERT INTO campuses (university_id, name, town, region, is_main) VALUES ('btu', 'Main Campus', 'Bolgatanga', 'Upper East', 1);
INSERT INTO campuses (university_id, name, town, region, is_main) VALUES ('cctu', 'Main Campus', 'Cape Coast', 'Central', 1);
INSERT INTO campuses (university_id, name, town, region, is_main) VALUES ('kstu', 'Main Campus', 'Kumasi', 'Ashanti', 1);
INSERT INTO campuses (university_id, name, town, region, is_main) VALUES ('ktu', 'Main Campus', 'Koforidua', 'Eastern', 1);
INSERT INTO campuses (university_id, name, town, region, is_main) VALUES ('ktu', 'Somanya Campus', 'Somanya', 'Eastern', 0);
INSERT INTO campuses (university_id, name, town, region, is_main) VALUES ('tatu', 'Main Campus', 'Tamale', 'Northern', 1);
INSERT INTO campuses (university_id, name, town, region, is_main) VALUES ('htu', 'Main Campus', 'Ho', 'Volta', 1);
INSERT INTO campuses (university_id, name, town, region, is_main) VALUES ('ttu', 'Main Campus', 'Takoradi', 'Western', 1);
INSERT INTO campuses (university_id, name, town, region, is_main) VALUES ('stu', 'Main Campus', 'Sunyani', 'Bono', 1);
INSERT INTO campuses (university_id, name, town, region, is_main) VALUES ('wtu', 'Main Campus', 'Wa', 'Upper West', 1);
INSERT INTO campuses (university_id, name, town, region, is_main) VALUES ('rmu', 'Main Campus', 'Nungua, Accra', 'Greater Accra', 1);
INSERT INTO campuses (university_id, name, town, region, is_main) VALUES ('gij', 'Main Campus', 'Accra', 'Greater Accra', 1);
INSERT INTO campuses (university_id, name, town, region, is_main) VALUES ('gism', 'Main Campus', 'Accra', 'Greater Accra', 1);
INSERT INTO campuses (university_id, name, town, region, is_main) VALUES ('nafti', 'Main Campus', 'Accra', 'Greater Accra', 1);
INSERT INTO campuses (university_id, name, town, region, is_main) VALUES ('ashesi', 'Berekuso Campus', 'Berekuso', 'Eastern', 1);
INSERT INTO campuses (university_id, name, town, region, is_main) VALUES ('central', 'Miotso Campus (Main)', 'Miotso, near Dawhenya', 'Greater Accra', 1);
INSERT INTO campuses (university_id, name, town, region, is_main) VALUES ('central', 'Mataheko Campus', 'Mataheko, Accra', 'Greater Accra', 0);
INSERT INTO campuses (university_id, name, town, region, is_main) VALUES ('central', 'Christ Temple Campus', 'Ring Road West, Accra', 'Greater Accra', 0);
INSERT INTO campuses (university_id, name, town, region, is_main) VALUES ('central', 'Kumasi Campus', 'Kumasi', 'Ashanti', 0);
INSERT INTO campuses (university_id, name, town, region, is_main) VALUES ('vvu', 'Oyibi Campus (Main)', 'Oyibi', 'Greater Accra', 1);
INSERT INTO campuses (university_id, name, town, region, is_main) VALUES ('vvu', 'Techiman Campus', 'Techiman', 'Bono East', 0);
INSERT INTO campuses (university_id, name, town, region, is_main) VALUES ('vvu', 'Kumasi Campus', 'Kumasi', 'Ashanti', 0);
INSERT INTO campuses (university_id, name, town, region, is_main) VALUES ('pentvars', 'Sowutuom Campus', 'Sowutuom, Accra', 'Greater Accra', 1);
INSERT INTO campuses (university_id, name, town, region, is_main) VALUES ('anu', 'Main Campus', 'Koforidua', 'Eastern', 1);
INSERT INTO campuses (university_id, name, town, region, is_main) VALUES ('presbyuc', 'Okwahu Campus (Main)', 'Abetifi-Kwahu', 'Eastern', 1);
INSERT INTO campuses (university_id, name, town, region, is_main) VALUES ('presbyuc', 'Akuapem Campus', 'Akropong-Akuapem', 'Eastern', 0);
INSERT INTO campuses (university_id, name, town, region, is_main) VALUES ('presbyuc', 'Asante Akyem Campus', 'Agogo', 'Ashanti', 0);
INSERT INTO campuses (university_id, name, town, region, is_main) VALUES ('presbyuc', 'Tema Campus', 'Community 11, Tema', 'Greater Accra', 0);
INSERT INTO campuses (university_id, name, town, region, is_main) VALUES ('presbyuc', 'Kumasi Campus (Santasi)', 'Santasi, Kumasi', 'Ashanti', 0);
INSERT INTO campuses (university_id, name, town, region, is_main) VALUES ('methodist', 'Dansoman Campus', 'Dansoman, Accra', 'Greater Accra', 1);
INSERT INTO campuses (university_id, name, town, region, is_main) VALUES ('methodist', 'Wenchi Campus', 'Wenchi', 'Bono', 0);
INSERT INTO campuses (university_id, name, town, region, is_main) VALUES ('csuc', 'Santasi Campus', 'Santasi, Kumasi', 'Ashanti', 1);
INSERT INTO campuses (university_id, name, town, region, is_main) VALUES ('regent', 'Main Campus', 'Dansoman, Accra', 'Greater Accra', 1);
INSERT INTO campuses (university_id, name, town, region, is_main) VALUES ('wiuc', 'Agbogba Campus', 'Agbogba Junction, Accra', 'Greater Accra', 1);
INSERT INTO campuses (university_id, name, town, region, is_main) VALUES ('cug', 'Fiapre Campus', 'Fiapre, Sunyani', 'Bono', 1);
INSERT INTO campuses (university_id, name, town, region, is_main) VALUES ('epuc', 'Main Campus', 'Ho', 'Volta', 1);
INSERT INTO campuses (university_id, name, town, region, is_main) VALUES ('gbuc', 'Abuakwa Campus', 'Abuakwa, Kumasi', 'Ashanti', 1);
INSERT INTO campuses (university_id, name, town, region, is_main) VALUES ('garden-city', 'Main Campus', 'Kumasi', 'Ashanti', 1);
INSERT INTO campuses (university_id, name, town, region, is_main) VALUES ('radford', 'East Legon Campus (Main)', 'East Legon, Accra', 'Greater Accra', 1);
INSERT INTO campuses (university_id, name, town, region, is_main) VALUES ('spiritan', 'Ejisu Campus', 'Ejisu', 'Ashanti', 1);
INSERT INTO campuses (university_id, name, town, region, is_main) VALUES ('data-link', 'Tema Campus', 'Tema', 'Greater Accra', 1);
INSERT INTO campuses (university_id, name, town, region, is_main) VALUES ('data-link', 'Cape Coast Campus', 'Cape Coast', 'Central', 0);
INSERT INTO campuses (university_id, name, town, region, is_main) VALUES ('mountcrest', 'Kanda Campus', 'Kanda, Accra', 'Greater Accra', 1);
INSERT INTO campuses (university_id, name, town, region, is_main) VALUES ('ucaes', 'Bunso Campus', 'Bunso', 'Eastern', 1);
INSERT INTO campuses (university_id, name, town, region, is_main) VALUES ('kings', 'Aplaku Campus', 'Aplaku Hills, Accra', 'Greater Accra', 1);
INSERT INTO campuses (university_id, name, town, region, is_main) VALUES ('maranatha', 'Sowutuom Campus', 'Sowutuom, Accra', 'Greater Accra', 1);
INSERT INTO campuses (university_id, name, town, region, is_main) VALUES ('palm', 'Manya Campus', 'Shai Hills', 'Greater Accra', 1);
INSERT INTO campuses (university_id, name, town, region, is_main) VALUES ('aucc', 'Adabraka Campus', 'Adabraka, Accra', 'Greater Accra', 1);
INSERT INTO campuses (university_id, name, town, region, is_main) VALUES ('ait', 'Cantonments Campus', 'Cantonments, Accra', 'Greater Accra', 1);
INSERT INTO campuses (university_id, name, town, region, is_main) VALUES ('iucg', 'East Legon Campus', 'East Legon, Accra', 'Greater Accra', 1);
INSERT INTO campuses (university_id, name, town, region, is_main) VALUES ('knutsford', 'East Legon Campus', 'East Legon, Accra', 'Greater Accra', 1);
INSERT INTO campuses (university_id, name, town, region, is_main) VALUES ('lancaster-gh', 'Accra Campus', 'Accra', 'Greater Accra', 1);
INSERT INTO campuses (university_id, name, town, region, is_main) VALUES ('webster-gh', 'East Legon Campus', 'East Legon, Accra', 'Greater Accra', 1);
INSERT INTO campuses (university_id, name, town, region, is_main) VALUES ('zenith', 'Main Campus', 'Accra', 'Greater Accra', 1);
INSERT INTO campuses (university_id, name, town, region, is_main) VALUES ('academic-city', 'Haatso Campus', 'Haatso, Accra', 'Greater Accra', 1);
INSERT INTO campuses (university_id, name, town, region, is_main) VALUES ('bluecrest', 'Kokomlemle Campus (Main)', 'Kokomlemle, Accra', 'Greater Accra', 1);
INSERT INTO campuses (university_id, name, town, region, is_main) VALUES ('catholic-institute', 'Accra North Campus', 'Accra North', 'Greater Accra', 1);
INSERT INTO campuses (university_id, name, town, region, is_main) VALUES ('anglican', 'Nkoranza Campus', 'Nkoranza', 'Bono East', 1);
INSERT INTO campuses (university_id, name, town, region, is_main) VALUES ('anglican', 'Teshie Campus', 'Teshie, Accra', 'Greater Accra', 0);
INSERT INTO campuses (university_id, name, town, region, is_main) VALUES ('baptist', 'Abuakwa Campus', 'Abuakwa-Kumasi', 'Ashanti', 1);
INSERT INTO campuses (university_id, name, town, region, is_main) VALUES ('christ-apostolic', 'Main Campus', 'Kumasi', 'Ashanti', 1);
INSERT INTO campuses (university_id, name, town, region, is_main) VALUES ('dominion', 'Main Campus', 'Accra', 'Greater Accra', 1);
INSERT INTO campuses (university_id, name, town, region, is_main) VALUES ('ghana-christian', 'Main Campus', 'Accra', 'Greater Accra', 1);
INSERT INTO campuses (university_id, name, town, region, is_main) VALUES ('marshalls', 'Main Campus', 'Accra', 'Greater Accra', 1);
INSERT INTO campuses (university_id, name, town, region, is_main) VALUES ('perez', 'Main Campus', 'Winneba', 'Central', 1);
INSERT INTO campuses (university_id, name, town, region, is_main) VALUES ('west-end', 'Main Campus', 'Accra', 'Greater Accra', 1);
INSERT INTO campuses (university_id, name, town, region, is_main) VALUES ('advanced-business', 'Main Campus', 'Accra', 'Greater Accra', 1);
INSERT INTO campuses (university_id, name, town, region, is_main) VALUES ('kaaf', 'Main Campus', 'Gomoa Fetteh Kakraba', 'Central', 1);
INSERT INTO campuses (university_id, name, town, region, is_main) VALUES ('heritage-christian', 'Main Campus', 'Amasaman', 'Greater Accra', 1);
INSERT INTO campuses (university_id, name, town, region, is_main) VALUES ('ensign', 'Kpong Campus', 'Kpong', 'Eastern', 1);