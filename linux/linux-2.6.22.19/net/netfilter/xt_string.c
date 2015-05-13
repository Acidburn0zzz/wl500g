/* String matching match for iptables
 *
 * (C) 2005 Pablo Neira Ayuso <pablo@eurodev.net>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation.
 */

#include <linux/init.h>
#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/skbuff.h>
#include <linux/netfilter/x_tables.h>
#include <linux/netfilter/xt_string.h>
#include <linux/textsearch.h>

MODULE_AUTHOR("Pablo Neira Ayuso <pablo@eurodev.net>");
MODULE_DESCRIPTION("IP tables string match module");
MODULE_LICENSE("GPL");
MODULE_ALIAS("ipt_string");
MODULE_ALIAS("ip6t_string");

static bool
match(const struct sk_buff *skb, struct xt_action_param *par)
{
	const struct xt_string_info *conf = par->matchinfo;
	struct ts_state state;
	bool invert;

	memset(&state, 0, sizeof(struct ts_state));
	invert = conf->u.v1.flags & XT_STRING_FLAG_INVERT;

	return (skb_find_text((struct sk_buff *)skb, conf->from_offset,
			     conf->to_offset, conf->config, &state)
			     != UINT_MAX) ^ invert;
}

#define STRING_TEXT_PRIV(m) ((struct xt_string_info *) m)

static bool checkentry(const struct xt_mtchk_param *par)
{
	struct xt_string_info *conf = par->matchinfo;
	struct ts_config *ts_conf;
	int flags = TS_AUTOLOAD;

	/* Damn, can't handle this case properly with iptables... */
	if (conf->from_offset > conf->to_offset)
		return 0;
	if (conf->algo[XT_STRING_MAX_ALGO_NAME_SIZE - 1] != '\0')
		return 0;
	if (conf->patlen > XT_STRING_MAX_PATTERN_SIZE)
		return 0;
	if (conf->u.v1.flags &
	    ~(XT_STRING_FLAG_IGNORECASE | XT_STRING_FLAG_INVERT))
		return -EINVAL;
	if (conf->u.v1.flags & XT_STRING_FLAG_IGNORECASE)
		flags |= TS_IGNORECASE;
	ts_conf = textsearch_prepare(conf->algo, conf->pattern, conf->patlen,
				     GFP_KERNEL, flags);
	if (IS_ERR(ts_conf))
		return 0;

	conf->config = ts_conf;

	return 1;
}

static void destroy(const struct xt_mtdtor_param *par)
{
	textsearch_destroy(STRING_TEXT_PRIV(par->matchinfo)->config);
}

static struct xt_match xt_string_match __read_mostly = {
	.name 		= "string",
	.revision	= 1,
	.family		= NFPROTO_UNSPEC,
	.checkentry	= checkentry,
	.match 		= match,
	.destroy 	= destroy,
	.matchsize	= sizeof(struct xt_string_info),
	.me 		= THIS_MODULE
};

static int __init xt_string_init(void)
{
	return xt_register_match(&xt_string_match);
}

static void __exit xt_string_fini(void)
{
	xt_unregister_match(&xt_string_match);
}

module_init(xt_string_init);
module_exit(xt_string_fini);
