module git.c.repository;

extern (C):

/*
 * Copyright (C) the libgit2 contributors. All rights reserved.
 *
 * This file is part of libgit2, distributed under the GNU GPL v2 with
 * a Linking Exception. For full terms see the included COPYING file.
 */

import std.conv;

import git.c.common;
import git.c.types;
import git.c.oid;

/**
 * @file git2/repository.h
 * @brief Git repository management routines
 * @defgroup git_repository Git repository management routines
 * @ingroup Git
 * @{
 */


/**
 * Open a git repository.
 *
 * The 'path' argument must point to either a git repository
 * folder, or an existing work dir.
 *
 * The method will automatically detect if 'path' is a normal
 * or bare repository or fail is 'path' is neither.
 *
 * @param out pointer to the repo which will be opened
 * @param path the path to the repository
 * @return 0 or an error code
 */
int git_repository_open(git_repository **out_, const(char)* path);

/**
 * Create a "fake" repository to wrap an object database
 *
 * Create a repository object to wrap an object database to be used
 * with the API when all you have is an object database. This doesn't
 * have any paths associated with it, so use with care.
 *
 * @param out pointer to the repo
 * @param odb the object database to wrap
 * @return 0 or an error code
 */
int git_repository_wrap_odb(git_repository **out_, git_odb *odb);

/**
 * Look for a git repository and copy its path in the given buffer.
 * The lookup start from base_path and walk across parent directories
 * if nothing has been found. The lookup ends when the first repository
 * is found, or when reaching a directory referenced in ceiling_dirs
 * or when the filesystem changes (in case across_fs is true).
 *
 * The method will automatically detect if the repository is bare
 * (if there is a repository).
 *
 * @param path_out The user allocated buffer which will
 * contain the found path.
 *
 * @param path_size repository_path size
 *
 * @param start_path The base path where the lookup starts.
 *
 * @param across_fs If true, then the lookup will not stop when a
 * filesystem device change is detected while exploring parent directories.
 *
 * @param ceiling_dirs A GIT_PATH_LIST_SEPARATOR separated list of
 * absolute symbolic link free paths. The lookup will stop when any
 * of this paths is reached. Note that the lookup always performs on
 * start_path no matter start_path appears in ceiling_dirs ceiling_dirs
 * might be NULL (which is equivalent to an empty string)
 *
 * @return 0 or an error code
 */
int git_repository_discover(
		char *path_out,
		size_t path_size,
		const(char)* start_path,
		int across_fs,
		const(char)* ceiling_dirs);

/**
 * Option flags for `git_repository_open_ext`.
 *
 * * GIT_REPOSITORY_OPEN_NO_SEARCH - Only open the repository if it can be
 *   immediately found in the start_path.  Do not walk up from the
 *   start_path looking at parent directories.
 * * GIT_REPOSITORY_OPEN_CROSS_FS - Unless this flag is set, open will not
 *   continue searching across filesystem boundaries (i.e. when `st_dev`
 *   changes from the `stat` system call).  (E.g. Searching in a user's home
 *   directory "/home/user/source/" will not return "/.git/" as the found
 *   repo if "/" is a different filesystem than "/home".)
 */
enum git_repository_open_flag_t {
	GIT_REPOSITORY_OPEN_NO_SEARCH = (1 << 0),
	GIT_REPOSITORY_OPEN_CROSS_FS  = (1 << 1),
} ;

/**
 * Find and open a repository with extended controls.
 *
 * @param out Pointer to the repo which will be opened.  This can
 *        actually be NULL if you only want to use the error code to
 *        see if a repo at this path could be opened.
 * @param path Path to open as git repository.  If the flags
 *        permit "searching", then this can be a path to a subdirectory
 *        inside the working directory of the repository.
 * @param flags A combination of the GIT_REPOSITORY_OPEN flags above.
 * @param ceiling_dirs A GIT_PATH_LIST_SEPARATOR delimited list of path
 *        prefixes at which the search for a containing repository should
 *        terminate.
 * @return 0 on success, GIT_ENOTFOUND if no repository could be found,
 *        or -1 if there was a repository but open failed for some reason
 *        (such as repo corruption or system errors).
 */
int git_repository_open_ext(
	git_repository **out_,
	const(char)* path,
	uint flags,
	const(char)* ceiling_dirs);

/**
 * Open a bare repository on the serverside.
 *
 * This is a fast open for bare repositories that will come in handy
 * if you're e.g. hosting git repositories and need to access them
 * efficiently
 *
 * @param out Pointer to the repo which will be opened.
 * @param bare_path Direct path to the bare repository
 * @return 0 on success, or an error code
 */
int git_repository_open_bare(git_repository **out_, const(char)* bare_path);

/**
 * Free a previously allocated repository
 *
 * Note that after a repository is free'd, all the objects it has spawned
 * will still exist until they are manually closed by the user
 * with `git_object_free`, but accessing any of the attributes of
 * an object without a backing repository will result in undefined
 * behavior
 *
 * @param repo repository handle to close. If NULL nothing occurs.
 */
void git_repository_free(git_repository *repo);

/**
 * Creates a new Git repository in the given folder.
 *
 * TODO:
 *	- Reinit the repository
 *
 * @param out pointer to the repo which will be created or reinitialized
 * @param path the path to the repository
 * @param is_bare if true, a Git repository without a working directory is
 *		created at the pointed path. If false, provided path will be
 *		considered as the working directory into which the .git directory
 *		will be created.
 *
 * @return 0 or an error code
 */
int git_repository_init(
	git_repository **out_,
	const(char)* path,
	uint is_bare);

/**
 * Option flags for `git_repository_init_ext`.
 *
 * These flags configure extra behaviors to `git_repository_init_ext`.
 * In every case, the default behavior is the zero value (i.e. flag is
 * not set).  Just OR the flag values together for the `flags` parameter
 * when initializing a new repo.  Details of individual values are:
 *
 * * BARE   - Create a bare repository with no working directory.
 * * NO_REINIT - Return an EEXISTS error if the repo_path appears to
 *        already be an git repository.
 * * NO_DOTGIT_DIR - Normally a "/.git/" will be appended to the repo
 *        path for non-bare repos (if it is not already there), but
 *        passing this flag prevents that behavior.
 * * MKDIR  - Make the repo_path (and workdir_path) as needed.  Init is
 *        always willing to create the ".git" directory even without this
 *        flag.  This flag tells init to create the trailing component of
 *        the repo and workdir paths as needed.
 * * MKPATH - Recursively make all components of the repo and workdir
 *        paths as necessary.
 * * EXTERNAL_TEMPLATE - libgit2 normally uses internal templates to
 *        initialize a new repo.  This flags enables external templates,
 *        looking the "template_path" from the options if set, or the
 *        `init.templatedir` global config if not, or falling back on
 *        "/usr/share/git-core/templates" if it exists.
 */
enum git_repository_init_flag_t {
	GIT_REPOSITORY_INIT_BARE              = (1u << 0),
	GIT_REPOSITORY_INIT_NO_REINIT         = (1u << 1),
	GIT_REPOSITORY_INIT_NO_DOTGIT_DIR     = (1u << 2),
	GIT_REPOSITORY_INIT_MKDIR             = (1u << 3),
	GIT_REPOSITORY_INIT_MKPATH            = (1u << 4),
	GIT_REPOSITORY_INIT_EXTERNAL_TEMPLATE = (1u << 5),
} ;

/**
 * Mode options for `git_repository_init_ext`.
 *
 * Set the mode field of the `git_repository_init_options` structure
 * either to the custom mode that you would like, or to one of the
 * following modes:
 *
 * * SHARED_UMASK - Use permissions configured by umask - the default.
 * * SHARED_GROUP - Use "--shared=group" behavior, chmod'ing the new repo
 *        to be group writable and "g+sx" for sticky group assignment.
 * * SHARED_ALL - Use "--shared=all" behavior, adding world readability.
 * * Anything else - Set to custom value.
 */
enum git_repository_init_mode_t {
	GIT_REPOSITORY_INIT_SHARED_UMASK = octal!0,
	GIT_REPOSITORY_INIT_SHARED_GROUP = octal!2775,
	GIT_REPOSITORY_INIT_SHARED_ALL   = octal!2777,
} ;

/**
 * Extended options structure for `git_repository_init_ext`.
 *
 * This contains extra options for `git_repository_init_ext` that enable
 * additional initialization features.  The fields are:
 *
 * * flags - Combination of GIT_REPOSITORY_INIT flags above.
 * * mode  - Set to one of the standard GIT_REPOSITORY_INIT_SHARED_...
 *        constants above, or to a custom value that you would like.
 * * workdir_path - The path to the working dir or NULL for default (i.e.
 *        repo_path parent on non-bare repos).  IF THIS IS RELATIVE PATH,
 *        IT WILL BE EVALUATED RELATIVE TO THE REPO_PATH.  If this is not
 *        the "natural" working directory, a .git gitlink file will be
 *        created here linking to the repo_path.
 * * description - If set, this will be used to initialize the "description"
 *        file in the repository, instead of using the template content.
 * * template_path - When GIT_REPOSITORY_INIT_EXTERNAL_TEMPLATE is set,
 *        this contains the path to use for the template directory.  If
 *        this is NULL, the config or default directory options will be
 *        used instead.
 * * initial_head - The name of the head to point HEAD at.  If NULL, then
 *        this will be treated as "master" and the HEAD ref will be set
 *        to "refs/heads/master".  If this begins with "refs/" it will be
 *        used verbatim; otherwise "refs/heads/" will be prefixed.
 * * origin_url - If this is non-NULL, then after the rest of the
 *        repository initialization is completed, an "origin" remote
 *        will be added pointing to this URL.
 */
struct git_repository_init_options {
	uint version_;
	uint32_t    flags;
	uint32_t    mode;
	const(char)* workdir_path;
	const(char)* description;
	const(char)* template_path;
	const(char)* initial_head;
	const(char)* origin_url;
} ;

enum GIT_REPOSITORY_INIT_OPTIONS_VERSION = 1;
enum git_repository_init_options GIT_REPOSITORY_INIT_OPTIONS_INIT = { GIT_REPOSITORY_INIT_OPTIONS_VERSION };

/**
 * Create a new Git repository in the given folder with extended controls.
 *
 * This will initialize a new git repository (creating the repo_path
 * if requested by flags) and working directory as needed.  It will
 * auto-detect the case sensitivity of the file system and if the
 * file system supports file mode bits correctly.
 *
 * @param out Pointer to the repo which will be created or reinitialized.
 * @param repo_path The path to the repository.
 * @param opts Pointer to git_repository_init_options struct.
 * @return 0 or an error code on failure.
 */
int git_repository_init_ext(
	git_repository **out_,
	const(char)* repo_path,
	git_repository_init_options *opts);

/**
 * Retrieve and resolve the reference pointed at by HEAD.
 *
 * The returned `git_reference` will be owned by caller and
 * `git_reference_free()` must be called when done with it to release the
 * allocated memory and prevent a leak.
 *
 * @param out pointer to the reference which will be retrieved
 * @param repo a repository object
 *
 * @return 0 on success, GIT_EORPHANEDHEAD when HEAD points to a non existing
 * branch, GIT_ENOTFOUND when HEAD is missing; an error code otherwise
 */
int git_repository_head(git_reference **out_, git_repository *repo);

/**
 * Check if a repository's HEAD is detached
 *
 * A repository's HEAD is detached when it points directly to a commit
 * instead of a branch.
 *
 * @param repo Repo to test
 * @return 1 if HEAD is detached, 0 if it's not; error code if there
 * was an error.
 */
int git_repository_head_detached(git_repository *repo);

/**
 * Check if the current branch is an orphan
 *
 * An orphan branch is one named from HEAD but which doesn't exist in
 * the refs namespace, because it doesn't have any commit to point to.
 *
 * @param repo Repo to test
 * @return 1 if the current branch is an orphan, 0 if it's not; error
 * code if there was an error
 */
int git_repository_head_orphan(git_repository *repo);

/**
 * Check if a repository is empty
 *
 * An empty repository has just been initialized and contains
 * no references.
 *
 * @param repo Repo to test
 * @return 1 if the repository is empty, 0 if it isn't, error code
 * if the repository is corrupted
 */
int git_repository_is_empty(git_repository *repo);

/**
 * Get the path of this repository
 *
 * This is the path of the `.git` folder for normal repositories,
 * or of the repository itself for bare repositories.
 *
 * @param repo A repository object
 * @return the path to the repository
 */
const(char)*  git_repository_path(git_repository *repo);

/**
 * Get the path of the working directory for this repository
 *
 * If the repository is bare, this function will always return
 * NULL.
 *
 * @param repo A repository object
 * @return the path to the working dir, if it exists
 */
const(char)*  git_repository_workdir(git_repository *repo);

/**
 * Set the path to the working directory for this repository
 *
 * The working directory doesn't need to be the same one
 * that contains the `.git` folder for this repository.
 *
 * If this repository is bare, setting its working directory
 * will turn it into a normal repository, capable of performing
 * all the common workdir operations (checkout, status, index
 * manipulation, etc).
 *
 * @param repo A repository object
 * @param workdir The path to a working directory
 * @param update_gitlink Create/update gitlink in workdir and set config
 *        "core.worktree" (if workdir is not the parent of the .git directory)
 * @return 0, or an error code
 */
int git_repository_set_workdir(
	git_repository *repo, const(char)* workdir, int update_gitlink);

/**
 * Check if a repository is bare
 *
 * @param repo Repo to test
 * @return 1 if the repository is bare, 0 otherwise.
 */
int git_repository_is_bare(git_repository *repo);

/**
 * Get the configuration file for this repository.
 *
 * If a configuration file has not been set, the default
 * config set for the repository will be returned, including
 * global and system configurations (if they are available).
 *
 * The configuration file must be freed once it's no longer
 * being used by the user.
 *
 * @param out Pointer to store the loaded config file
 * @param repo A repository object
 * @return 0, or an error code
 */
int git_repository_config(git_config **out_, git_repository *repo);

/**
 * Get the Object Database for this repository.
 *
 * If a custom ODB has not been set, the default
 * database for the repository will be returned (the one
 * located in `.git/objects`).
 *
 * The ODB must be freed once it's no longer being used by
 * the user.
 *
 * @param out Pointer to store the loaded ODB
 * @param repo A repository object
 * @return 0, or an error code
 */
int git_repository_odb(git_odb **out_, git_repository *repo);

/**
 * Get the Reference Database Backend for this repository.
 *
 * If a custom refsdb has not been set, the default database for
 * the repository will be returned (the one that manipulates loose
 * and packed references in the `.git` directory).
 *
 * The refdb must be freed once it's no longer being used by
 * the user.
 *
 * @param out Pointer to store the loaded refdb
 * @param repo A repository object
 * @return 0, or an error code
 */
int git_repository_refdb(git_refdb **out_, git_repository *repo);

/**
 * Get the Index file for this repository.
 *
 * If a custom index has not been set, the default
 * index for the repository will be returned (the one
 * located in `.git/index`).
 *
 * The index must be freed once it's no longer being used by
 * the user.
 *
 * @param out Pointer to store the loaded index
 * @param repo A repository object
 * @return 0, or an error code
 */
int git_repository_index(git_index **out_, git_repository *repo);

/**
 * Retrieve git's prepared message
 *
 * Operations such as git revert/cherry-pick/merge with the -n option
 * stop just short of creating a commit with the changes and save
 * their prepared message in .git/MERGE_MSG so the next git-commit
 * execution can present it to the user for them to amend if they
 * wish.
 *
 * Use this function to get the contents of this file. Don't forget to
 * remove the file after you create the commit.
 *
 * If the repository message exists and there are no errors reading it, this
 * returns the bytes needed to store the message in memory (i.e. message
 * file size plus one terminating NUL byte).  That value is returned even if
 * `out` is NULL or `len` is shorter than the necessary size.
 *
 * The `out` buffer will *always* be NUL terminated, even if truncation
 * occurs.
 *
 * @param out Buffer to write data into or NULL to just read required size
 * @param len Length of `out` buffer in bytes
 * @param repo Repository to read prepared message from
 * @return GIT_ENOUTFOUND if no message exists, other value < 0 for other
 *         errors, or total bytes in message (may be > `len`) on success
 */
int git_repository_message(char *out_, size_t len, git_repository *repo);

/**
 * Remove git's prepared message.
 *
 * Remove the message that `git_repository_message` retrieves.
 */
int git_repository_message_remove(git_repository *repo);

/**
 * Remove all the metadata associated with an ongoing git merge, including
 * MERGE_HEAD, MERGE_MSG, etc.
 *
 * @param repo A repository object
 * @return 0 on success, or error
 */
int git_repository_merge_cleanup(git_repository *repo);

alias git_repository_fetchhead_foreach_cb = int function(const(char)* ref_name,
	const(char)* remote_url,
	const(git_oid)* oid,
	uint is_merge,
	void *payload);

/**
 * Call callback 'callback' for each entry in the given FETCH_HEAD file.
 *
 * @param repo A repository object
 * @param callback Callback function
 * @param payload Pointer to callback data (optional)
 * @return 0 on success, GIT_ENOTFOUND, GIT_EUSER or error
 */
int git_repository_fetchhead_foreach(git_repository *repo,
	git_repository_fetchhead_foreach_cb callback,
	void *payload);

alias git_repository_mergehead_foreach_cb = int function(const(git_oid)* oid,
	void *payload);

/**
 * If a merge is in progress, call callback 'cb' for each commit ID in the
 * MERGE_HEAD file.
 *
 * @param repo A repository object
 * @param callback Callback function
 * @param payload Pointer to callback data (optional)
 * @return 0 on success, GIT_ENOTFOUND, GIT_EUSER or error
 */
int git_repository_mergehead_foreach(git_repository *repo,
	git_repository_mergehead_foreach_cb callback,
	void *payload);

/**
 * Calculate hash of file using repository filtering rules.
 *
 * If you simply want to calculate the hash of a file on disk with no filters,
 * you can just use the `git_odb_hashfile()` API.  However, if you want to
 * hash a file in the repository and you want to apply filtering rules (e.g.
 * crlf filters) before generating the SHA, then use this function.
 *
 * @param out Output value of calculated SHA
 * @param repo Repository pointer
 * @param path Path to file on disk whose contents should be hashed. If the
 *             repository is not NULL, this can be a relative path.
 * @param type The object type to hash as (e.g. GIT_OBJ_BLOB)
 * @param as_path The path to use to look up filtering rules. If this is
 *             NULL, then the `path` parameter will be used instead. If
 *             this is passed as the empty string, then no filters will be
 *             applied when calculating the hash.
 */
int git_repository_hashfile(
	git_oid *out_,
	git_repository *repo,
	const(char)* path,
	git_otype type,
	const(char)* as_path);

/**
 * Make the repository HEAD point to the specified reference.
 *
 * If the provided reference points to a Tree or a Blob, the HEAD is
 * unaltered and -1 is returned.
 *
 * If the provided reference points to a branch, the HEAD will point
 * to that branch, staying attached, or become attached if it isn't yet.
 * If the branch doesn't exist yet, no error will be return. The HEAD
 * will then be attached to an unborn branch.
 *
 * Otherwise, the HEAD will be detached and will directly point to
 * the Commit.
 *
 * @param repo Repository pointer
 * @param refname Canonical name of the reference the HEAD should point at
 * @return 0 on success, or an error code
 */
int git_repository_set_head(
	git_repository* repo,
	const char* refname);

/**
 * Make the repository HEAD directly point to the Commit.
 *
 * If the provided committish cannot be found in the repository, the HEAD
 * is unaltered and GIT_ENOTFOUND is returned.
 *
 * If the provided commitish cannot be peeled into a commit, the HEAD
 * is unaltered and -1 is returned.
 *
 * Otherwise, the HEAD will eventually be detached and will directly point to
 * the peeled Commit.
 *
 * @param repo Repository pointer
 * @param commitish Object id of the Commit the HEAD should point to
 * @return 0 on success, or an error code
 */
int git_repository_set_head_detached(
	git_repository* repo,
	const git_oid* commitish);

/**
 * Detach the HEAD.
 *
 * If the HEAD is already detached and points to a Commit, 0 is returned.
 *
 * If the HEAD is already detached and points to a Tag, the HEAD is
 * updated into making it point to the peeled Commit, and 0 is returned.
 *
 * If the HEAD is already detached and points to a non commitish, the HEAD is
 * unaltered, and -1 is returned.
 *
 * Otherwise, the HEAD will be detached and point to the peeled Commit.
 *
 * @param repo Repository pointer
 * @return 0 on success, GIT_EORPHANEDHEAD when HEAD points to a non existing
 * branch or an error code
 */
int git_repository_detach_head(
	git_repository* repo);

enum git_repository_state_t {
	GIT_REPOSITORY_STATE_NONE,
	GIT_REPOSITORY_STATE_MERGE,
	GIT_REPOSITORY_STATE_REVERT,
	GIT_REPOSITORY_STATE_CHERRY_PICK,
	GIT_REPOSITORY_STATE_BISECT,
	GIT_REPOSITORY_STATE_REBASE,
	GIT_REPOSITORY_STATE_REBASE_INTERACTIVE,
	GIT_REPOSITORY_STATE_REBASE_MERGE,
	GIT_REPOSITORY_STATE_APPLY_MAILBOX,
	GIT_REPOSITORY_STATE_APPLY_MAILBOX_OR_REBASE,
} ;

/**
 * Determines the status of a git repository - ie, whether an operation
 * (merge, cherry-pick, etc) is in progress.
 *
 * @param repo Repository pointer
 * @return The state of the repository
 */
int git_repository_state(git_repository *repo);

/**
 * Sets the active namespace for this Git Repository
 *
 * This namespace affects all reference operations for the repo.
 * See `man gitnamespaces`
 *
 * @param repo The repo
 * @param nmspace The namespace. This should not include the refs
 *	folder, e.g. to namespace all references under `refs/namespaces/foo/`,
 *	use `foo` as the namespace.
 *	@return 0 on success, -1 on error
 */
int git_repository_set_namespace(git_repository *repo, const(char)* nmspace);

/**
 * Get the currently active namespace for this repository
 *
 * @param repo The repo
 * @return the active namespace, or NULL if there isn't one
 */
const(char)*  git_repository_get_namespace(git_repository *repo);


/**
 * Determine if the repository was a shallow clone
 *
 * @param repo The repository
 * @return 1 if shallow, zero if not
 */
int git_repository_is_shallow(git_repository *repo);



