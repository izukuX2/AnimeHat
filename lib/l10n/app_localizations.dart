import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('fr')
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'AnimeHat'**
  String get appTitle;

  /// No description provided for @welcomeMessage.
  ///
  /// In en, this message translates to:
  /// **'Welcome to AnimeHat!'**
  String get welcomeMessage;

  /// No description provided for @developer.
  ///
  /// In en, this message translates to:
  /// **'Made with Passion by izukuX2'**
  String get developer;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get arabic;

  /// No description provided for @french.
  ///
  /// In en, this message translates to:
  /// **'French'**
  String get french;

  /// No description provided for @popularAnime.
  ///
  /// In en, this message translates to:
  /// **'Popular Anime'**
  String get popularAnime;

  /// No description provided for @explore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get explore;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @latestNews.
  ///
  /// In en, this message translates to:
  /// **'Latest Anime News'**
  String get latestNews;

  /// No description provided for @broadcastSchedule.
  ///
  /// In en, this message translates to:
  /// **'Broadcast Schedule'**
  String get broadcastSchedule;

  /// No description provided for @episodes.
  ///
  /// In en, this message translates to:
  /// **'Episodes'**
  String get episodes;

  /// No description provided for @series.
  ///
  /// In en, this message translates to:
  /// **'Series'**
  String get series;

  /// No description provided for @movies.
  ///
  /// In en, this message translates to:
  /// **'Movies'**
  String get movies;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @characters.
  ///
  /// In en, this message translates to:
  /// **'Characters'**
  String get characters;

  /// No description provided for @library.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get library;

  /// No description provided for @community.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get community;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @latestEpisodes.
  ///
  /// In en, this message translates to:
  /// **'Latest Episodes'**
  String get latestEpisodes;

  /// No description provided for @currentSeason.
  ///
  /// In en, this message translates to:
  /// **'Current Season'**
  String get currentSeason;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get seeAll;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcomeBack;

  /// No description provided for @signInToContinue.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue your journey'**
  String get signInToContinue;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailAddress;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @joinCommunity.
  ///
  /// In en, this message translates to:
  /// **'Join the AnimeHat community'**
  String get joinCommunity;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @signup.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signup;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// No description provided for @createOne.
  ///
  /// In en, this message translates to:
  /// **'Create one'**
  String get createOne;

  /// No description provided for @pleaseFillAllFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all fields'**
  String get pleaseFillAllFields;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @appTheme.
  ///
  /// In en, this message translates to:
  /// **'App Theme'**
  String get appTheme;

  /// No description provided for @customizeAppearance.
  ///
  /// In en, this message translates to:
  /// **'Customize colors and appearance'**
  String get customizeAppearance;

  /// No description provided for @backgroundSync.
  ///
  /// In en, this message translates to:
  /// **'Background Sync'**
  String get backgroundSync;

  /// No description provided for @autoUpload.
  ///
  /// In en, this message translates to:
  /// **'Auto-Upload (Sync)'**
  String get autoUpload;

  /// No description provided for @updateLibraryBackground.
  ///
  /// In en, this message translates to:
  /// **'Update library in the background'**
  String get updateLibraryBackground;

  /// No description provided for @syncSpeed.
  ///
  /// In en, this message translates to:
  /// **'Sync Speed'**
  String get syncSpeed;

  /// No description provided for @manualFullSync.
  ///
  /// In en, this message translates to:
  /// **'Manual Full Sync'**
  String get manualFullSync;

  /// No description provided for @forceUpdateLibrary.
  ///
  /// In en, this message translates to:
  /// **'Force update the entire library now'**
  String get forceUpdateLibrary;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @backupAllData.
  ///
  /// In en, this message translates to:
  /// **'Backup All Data'**
  String get backupAllData;

  /// No description provided for @exportDataFolder.
  ///
  /// In en, this message translates to:
  /// **'Export all anime data and links to a folder'**
  String get exportDataFolder;

  /// No description provided for @restoreAllData.
  ///
  /// In en, this message translates to:
  /// **'Restore All Data'**
  String get restoreAllData;

  /// No description provided for @importBackupFile.
  ///
  /// In en, this message translates to:
  /// **'Import anime data from a backup file'**
  String get importBackupFile;

  /// No description provided for @syncUserProfile.
  ///
  /// In en, this message translates to:
  /// **'Sync User Profile'**
  String get syncUserProfile;

  /// No description provided for @createUpdateProfile.
  ///
  /// In en, this message translates to:
  /// **'Create/Update your profile in database'**
  String get createUpdateProfile;

  /// No description provided for @offlineStorage.
  ///
  /// In en, this message translates to:
  /// **'Offline Storage'**
  String get offlineStorage;

  /// No description provided for @downloadAllData.
  ///
  /// In en, this message translates to:
  /// **'Download All Data'**
  String get downloadAllData;

  /// No description provided for @storeInfoOffline.
  ///
  /// In en, this message translates to:
  /// **'Store anime info and links for offline use'**
  String get storeInfoOffline;

  /// No description provided for @clearLocalCache.
  ///
  /// In en, this message translates to:
  /// **'Clear Local Cache'**
  String get clearLocalCache;

  /// No description provided for @freeUpSpace.
  ///
  /// In en, this message translates to:
  /// **'Free up space by removing cached data'**
  String get freeUpSpace;

  /// No description provided for @adminDashboard.
  ///
  /// In en, this message translates to:
  /// **'Admin Dashboard'**
  String get adminDashboard;

  /// No description provided for @manageApp.
  ///
  /// In en, this message translates to:
  /// **'Manage app settings, users, and content'**
  String get manageApp;

  /// No description provided for @checkForUpdates.
  ///
  /// In en, this message translates to:
  /// **'Check for Updates'**
  String get checkForUpdates;

  /// No description provided for @ensureLatestVersion.
  ///
  /// In en, this message translates to:
  /// **'Ensure you are running the latest version'**
  String get ensureLatestVersion;

  /// No description provided for @continueWatching.
  ///
  /// In en, this message translates to:
  /// **'Continue Watching'**
  String get continueWatching;

  /// No description provided for @userNotFound.
  ///
  /// In en, this message translates to:
  /// **'User not found'**
  String get userNotFound;

  /// No description provided for @overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overview;

  /// No description provided for @activity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get activity;

  /// No description provided for @animeStats.
  ///
  /// In en, this message translates to:
  /// **'Anime Stats'**
  String get animeStats;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @watching.
  ///
  /// In en, this message translates to:
  /// **'Watching'**
  String get watching;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @socialLinks.
  ///
  /// In en, this message translates to:
  /// **'Social Links'**
  String get socialLinks;

  /// No description provided for @noSocialLinks.
  ///
  /// In en, this message translates to:
  /// **'No social links added.'**
  String get noSocialLinks;

  /// No description provided for @joined.
  ///
  /// In en, this message translates to:
  /// **'Joined'**
  String get joined;

  /// No description provided for @noRecentActivity.
  ///
  /// In en, this message translates to:
  /// **'No recent activity'**
  String get noRecentActivity;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @signInOrCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Sign In/Create Account'**
  String get signInOrCreateAccount;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get logout;

  /// No description provided for @myAccount.
  ///
  /// In en, this message translates to:
  /// **'MY ACCOUNT'**
  String get myAccount;

  /// No description provided for @myLibrary.
  ///
  /// In en, this message translates to:
  /// **'MY LIBRARY'**
  String get myLibrary;

  /// No description provided for @loginToFavorite.
  ///
  /// In en, this message translates to:
  /// **'Please login to add to favorites'**
  String get loginToFavorite;

  /// No description provided for @loginToLibrary.
  ///
  /// In en, this message translates to:
  /// **'Please login to add to library'**
  String get loginToLibrary;

  /// No description provided for @selectCategory.
  ///
  /// In en, this message translates to:
  /// **'Select Category'**
  String get selectCategory;

  /// No description provided for @createNewCategory.
  ///
  /// In en, this message translates to:
  /// **'Create New Category'**
  String get createNewCategory;

  /// No description provided for @newCategory.
  ///
  /// In en, this message translates to:
  /// **'New Category'**
  String get newCategory;

  /// No description provided for @categoryName.
  ///
  /// In en, this message translates to:
  /// **'Category Name'**
  String get categoryName;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @loginToRate.
  ///
  /// In en, this message translates to:
  /// **'Please login to rate'**
  String get loginToRate;

  /// No description provided for @rateThisAnime.
  ///
  /// In en, this message translates to:
  /// **'Rate this Anime'**
  String get rateThisAnime;

  /// No description provided for @stars.
  ///
  /// In en, this message translates to:
  /// **'Stars'**
  String get stars;

  /// No description provided for @rate.
  ///
  /// In en, this message translates to:
  /// **'Rate'**
  String get rate;

  /// No description provided for @information.
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get information;

  /// No description provided for @plot.
  ///
  /// In en, this message translates to:
  /// **'Plot'**
  String get plot;

  /// No description provided for @viewEpisodes.
  ///
  /// In en, this message translates to:
  /// **'VIEW EPISODES'**
  String get viewEpisodes;

  /// No description provided for @favorited.
  ///
  /// In en, this message translates to:
  /// **'Favorited'**
  String get favorited;

  /// No description provided for @favorite.
  ///
  /// In en, this message translates to:
  /// **'Favorite'**
  String get favorite;

  /// No description provided for @inLibrary.
  ///
  /// In en, this message translates to:
  /// **'In Library'**
  String get inLibrary;

  /// No description provided for @comments.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get comments;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// No description provided for @released.
  ///
  /// In en, this message translates to:
  /// **'Released'**
  String get released;

  /// No description provided for @studio.
  ///
  /// In en, this message translates to:
  /// **'Studio'**
  String get studio;

  /// No description provided for @popularity.
  ///
  /// In en, this message translates to:
  /// **'Popularity'**
  String get popularity;

  /// No description provided for @members.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get members;

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @resumePlaying.
  ///
  /// In en, this message translates to:
  /// **'Resume Playing?'**
  String get resumePlaying;

  /// No description provided for @resumePrompt.
  ///
  /// In en, this message translates to:
  /// **'You stopped at {time}. Do you want to resume?'**
  String resumePrompt(String time);

  /// No description provided for @startOver.
  ///
  /// In en, this message translates to:
  /// **'Start Over'**
  String get startOver;

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// No description provided for @noEpisodesFound.
  ///
  /// In en, this message translates to:
  /// **'No episodes found.'**
  String get noEpisodesFound;

  /// No description provided for @episodePrefix.
  ///
  /// In en, this message translates to:
  /// **'Episode '**
  String get episodePrefix;

  /// No description provided for @season.
  ///
  /// In en, this message translates to:
  /// **'Season'**
  String get season;

  /// No description provided for @rating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get rating;

  /// No description provided for @failedToResolveLink.
  ///
  /// In en, this message translates to:
  /// **'Failed to resolve video link. Please try again.'**
  String get failedToResolveLink;

  /// No description provided for @selectQuality.
  ///
  /// In en, this message translates to:
  /// **'Select Quality'**
  String get selectQuality;

  /// No description provided for @noServersAvailable.
  ///
  /// In en, this message translates to:
  /// **'No servers available for this episode.'**
  String get noServersAvailable;

  /// No description provided for @mediaUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Media link unavailable.'**
  String get mediaUnavailable;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'RETRY'**
  String get retry;

  /// No description provided for @startingPlayer.
  ///
  /// In en, this message translates to:
  /// **'Starting Player'**
  String get startingPlayer;

  /// No description provided for @resolvingLink.
  ///
  /// In en, this message translates to:
  /// **'Resolving direct link for fastest speed...'**
  String get resolvingLink;

  /// No description provided for @epShort.
  ///
  /// In en, this message translates to:
  /// **'Ep'**
  String get epShort;

  /// No description provided for @auto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get auto;

  /// No description provided for @loginToPost.
  ///
  /// In en, this message translates to:
  /// **'Please login to post'**
  String get loginToPost;

  /// No description provided for @anonymous.
  ///
  /// In en, this message translates to:
  /// **'Anonymous'**
  String get anonymous;

  /// No description provided for @discussion.
  ///
  /// In en, this message translates to:
  /// **'Discussion'**
  String get discussion;

  /// No description provided for @postedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Posted successfully!'**
  String get postedSuccessfully;

  /// No description provided for @errorPrefix.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get errorPrefix;

  /// No description provided for @clubSuffix.
  ///
  /// In en, this message translates to:
  /// **'Club'**
  String get clubSuffix;

  /// No description provided for @postHint.
  ///
  /// In en, this message translates to:
  /// **'What\'s on your mind?'**
  String get postHint;

  /// No description provided for @noComments.
  ///
  /// In en, this message translates to:
  /// **'No comments yet.'**
  String get noComments;

  /// No description provided for @noPosts.
  ///
  /// In en, this message translates to:
  /// **'No posts yet.'**
  String get noPosts;

  /// No description provided for @loginToReply.
  ///
  /// In en, this message translates to:
  /// **'Please login to reply'**
  String get loginToReply;

  /// No description provided for @repliesSoon.
  ///
  /// In en, this message translates to:
  /// **'Replies to posts coming soon!'**
  String get repliesSoon;

  /// No description provided for @replyLabel.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get replyLabel;

  /// No description provided for @replyHint.
  ///
  /// In en, this message translates to:
  /// **'Write a reply...'**
  String get replyHint;

  /// No description provided for @replyAdded.
  ///
  /// In en, this message translates to:
  /// **'Reply added!'**
  String get replyAdded;

  /// No description provided for @spoiler.
  ///
  /// In en, this message translates to:
  /// **'Spoiler'**
  String get spoiler;

  /// No description provided for @showContent.
  ///
  /// In en, this message translates to:
  /// **'Show Content'**
  String get showContent;

  /// No description provided for @viewReplies.
  ///
  /// In en, this message translates to:
  /// **'View Replies'**
  String get viewReplies;

  /// No description provided for @hideReplies.
  ///
  /// In en, this message translates to:
  /// **'Hide Replies'**
  String get hideReplies;

  /// No description provided for @accessDenied.
  ///
  /// In en, this message translates to:
  /// **'Access Denied: You do not have permission to view this page.'**
  String get accessDenied;

  /// No description provided for @stats.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get stats;

  /// No description provided for @general.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get general;

  /// No description provided for @updates.
  ///
  /// In en, this message translates to:
  /// **'Updates'**
  String get updates;

  /// No description provided for @ads.
  ///
  /// In en, this message translates to:
  /// **'Ads'**
  String get ads;

  /// No description provided for @featured.
  ///
  /// In en, this message translates to:
  /// **'Featured'**
  String get featured;

  /// No description provided for @users.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get users;

  /// No description provided for @announce.
  ///
  /// In en, this message translates to:
  /// **'Announce'**
  String get announce;

  /// No description provided for @totalUsers.
  ///
  /// In en, this message translates to:
  /// **'Total Users'**
  String get totalUsers;

  /// No description provided for @totalPosts.
  ///
  /// In en, this message translates to:
  /// **'Total Posts'**
  String get totalPosts;

  /// No description provided for @systemLogs.
  ///
  /// In en, this message translates to:
  /// **'System Logs'**
  String get systemLogs;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @logsCleared.
  ///
  /// In en, this message translates to:
  /// **'Logs cleared'**
  String get logsCleared;

  /// No description provided for @noLogsFound.
  ///
  /// In en, this message translates to:
  /// **'No logs found'**
  String get noLogsFound;

  /// No description provided for @systemDiagnostics.
  ///
  /// In en, this message translates to:
  /// **'System Diagnostics'**
  String get systemDiagnostics;

  /// No description provided for @runIntegrityCheck.
  ///
  /// In en, this message translates to:
  /// **'Run Integrity Check'**
  String get runIntegrityCheck;

  /// No description provided for @runningDiagnostics.
  ///
  /// In en, this message translates to:
  /// **'Running diagnostics...'**
  String get runningDiagnostics;

  /// No description provided for @diagnosticsComplete.
  ///
  /// In en, this message translates to:
  /// **'Diagnostics Complete'**
  String get diagnosticsComplete;

  /// No description provided for @maintenance.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get maintenance;

  /// No description provided for @maintenanceMode.
  ///
  /// In en, this message translates to:
  /// **'Maintenance Mode'**
  String get maintenanceMode;

  /// No description provided for @maintenanceMessage.
  ///
  /// In en, this message translates to:
  /// **'Maintenance Message'**
  String get maintenanceMessage;

  /// No description provided for @updateMessage.
  ///
  /// In en, this message translates to:
  /// **'Update Message'**
  String get updateMessage;

  /// No description provided for @appUpdates.
  ///
  /// In en, this message translates to:
  /// **'App Updates'**
  String get appUpdates;

  /// No description provided for @latestVersion.
  ///
  /// In en, this message translates to:
  /// **'Latest Available Version'**
  String get latestVersion;

  /// No description provided for @minVersion.
  ///
  /// In en, this message translates to:
  /// **'Min Required Version'**
  String get minVersion;

  /// No description provided for @directUpdateUrl.
  ///
  /// In en, this message translates to:
  /// **'Direct Update URL (APK)'**
  String get directUpdateUrl;

  /// No description provided for @updateNotes.
  ///
  /// In en, this message translates to:
  /// **'Update Notes (Changelog)'**
  String get updateNotes;

  /// No description provided for @forceUpdate.
  ///
  /// In en, this message translates to:
  /// **'Force Update'**
  String get forceUpdate;

  /// No description provided for @saveUpdateSettings.
  ///
  /// In en, this message translates to:
  /// **'Save Update Settings'**
  String get saveUpdateSettings;

  /// No description provided for @adManagement.
  ///
  /// In en, this message translates to:
  /// **'Ad Management'**
  String get adManagement;

  /// No description provided for @showAdsGlobally.
  ///
  /// In en, this message translates to:
  /// **'Show Ads Globally'**
  String get showAdsGlobally;

  /// No description provided for @searchUsers.
  ///
  /// In en, this message translates to:
  /// **'Search users...'**
  String get searchUsers;

  /// No description provided for @activeAccount.
  ///
  /// In en, this message translates to:
  /// **'Active Account'**
  String get activeAccount;

  /// No description provided for @administrator.
  ///
  /// In en, this message translates to:
  /// **'Administrator'**
  String get administrator;

  /// No description provided for @newAnnouncement.
  ///
  /// In en, this message translates to:
  /// **'New Announcement'**
  String get newAnnouncement;

  /// No description provided for @broadcast.
  ///
  /// In en, this message translates to:
  /// **'Broadcast'**
  String get broadcast;

  /// No description provided for @announcementBroadcasted.
  ///
  /// In en, this message translates to:
  /// **'Announcement Broadcasted'**
  String get announcementBroadcasted;

  /// No description provided for @successImportant.
  ///
  /// In en, this message translates to:
  /// **'Success/Important'**
  String get successImportant;

  /// No description provided for @warningMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Warning/Maintenance'**
  String get warningMaintenance;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @content.
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get content;

  /// No description provided for @skipIntro.
  ///
  /// In en, this message translates to:
  /// **'Skip Intro'**
  String get skipIntro;

  /// No description provided for @autoSkipIntro.
  ///
  /// In en, this message translates to:
  /// **'Auto Skip Intro'**
  String get autoSkipIntro;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
