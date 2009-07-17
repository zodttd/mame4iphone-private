/*
 *  AltAdsSupport.h
 *  Docs2
 *
 *  Created by mark on 2/15/09.
 *  Copyright 2009 __MyCompanyName__. All rights reserved.
 *
 */

// Mobclix app id and ad id.
#define MOBCLIX_APP_ID  @"a771802a-c68b-44ff-aec7-29000850e412"
#define MOBCLIX_AD_ID	@"58a6e61a-60ff-102c-8da0-12313a002cd2"

// Admob app id. Two allows random selection if sharing the app. Otherwise make the same.
#define ADMOB_AD_ID1	@"a148e086678b92c"
#define ADMOB_AD_ID2	@"a148e086678b92c"

// MY own URL will fall through when ad type = 2 (my own).
#define MY_OWN_URL		@"http://www.zodttd.com/ads/categories_mame4iphone.php"

// URL to retrieve which ads to use on this app.
#define WHICH_ADS_URL	@"http://www.zodttd.com/ads/whichad_categories_mame4iphone.php"

// contents of which_ads_url must be somethign like: 0,1,2 (admob, mobclix, MY_OWN_URL) or 1,0,2 (mobclix, admob, MY_OWN_URL). If no own url, you can double up like (0,1,1) for mobclix, admob, admob. Or you can just use bigboss's and give him the $$ when you dont fill :)
