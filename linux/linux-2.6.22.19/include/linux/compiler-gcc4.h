/* Never include this file directly.  Include <linux/compiler.h> instead.  */

/* These definitions are for GCC v4.x.  */
#include <linux/compiler-gcc.h>

#ifdef CONFIG_FORCED_INLINING
# undef inline
# undef __inline__
# undef __inline
# define inline			inline		__attribute__((always_inline))
# define __inline__		__inline__	__attribute__((always_inline))
# define __inline		__inline	__attribute__((always_inline))
#endif

#define __used			__attribute__((__used__))
#define __attribute_used__	__used			/* deprecated */
#define __must_check 		__attribute__((warn_unused_result))
#define __compiler_offsetof(a,b) __builtin_offsetof(a,b)
#define __always_inline		inline __attribute__((always_inline))

/*
 * A trick to suppress uninitialized variable warning without generating any
 * code
 */
#define uninitialized_var(x) x = x

#if __GNUC_MINOR__ >= 3
/* Mark functions as cold. gcc will assume any path leading to a call
   to them will be unlikely.  This means a lot of manual unlikely()s
   are unnecessary now for any paths leading to the usual suspects
   like BUG(), printk(), panic() etc. [but let's keep them for now for
   older compilers]

   Early snapshots of gcc 4.3 don't support this and we can't detect this
   in the preprocessor, but we can live with this because they're unreleased.
   Maketime probing would be overkill here.

   gcc also has a __attribute__((__hot__)) to move hot functions into
   a special section, but I don't see any sense in this right now in
   the kernel context */
#define __cold			__attribute__((__cold__))


#if __GNUC_MINOR__ >= 5
/*
 * Mark a position in code as unreachable.  This can be used to
 * suppress control flow warnings after asm blocks that transfer
 * control elsewhere.
 *
 * Early snapshots of gcc 4.5 don't support this and we can't detect
 * this in the preprocessor, but we can live with this because they're
 * unreleased.  Really, we need to have autoconf for the kernel.
 */
#define unreachable() __builtin_unreachable()
#endif

#endif
