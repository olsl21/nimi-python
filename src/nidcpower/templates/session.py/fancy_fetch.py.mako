<%page args="f, config, method_template"/>\
<%
    '''Forwards to _fetch_multiple() with a nicer interface'''
    import build.helper as helper

    suffix = method_template['method_python_name_suffix']

    # We explicitly only support fetch_multiple and measure_multiple
    if f['python_name'] == 'fetch_multiple':
        param_list = 'timeout, count'
        in_compliances_return = ', in_compliances'
        in_compliance_unpack = ', in_compliance'
        in_compliance_value = 'in_compliance'
        channel_names_zipped = ''
        channel_name_unpack = ''
        channel_name_value = 'channel_names[0]'
    elif f['python_name'] == 'measure_multiple':
        param_list = ''
        in_compliances_return = ''
        in_compliance_unpack = ''
        in_compliance_value = 'None'
        channel_names_zipped = ', channel_names'
        channel_name_unpack = ', channel_name'
        channel_name_value = 'channel_name'
    else:
        raise ValueError('Only fetch_multiple and measure_multiple are supported. Got {0}'.format(f['python_name']))
%>\
    def ${f['python_name']}${suffix}(${helper.get_params_snippet(f, helper.ParameterUsageOptions.SESSION_METHOD_DECLARATION)}):
        '''${f['python_name']}

        ${helper.get_function_docstring(f, False, config, indent=8)}
        '''
        import collections
        Measurement = collections.namedtuple('Measurement', ['voltage', 'current', 'in_compliance', 'channel'])

        voltage_measurements, current_measurements${in_compliances_return} = self._${f['python_name']}(${param_list})

        if self._repeated_capability == '':
            channel_names = self._get_channel_names(range(self.channel_count))
        else:
            # first_channel_name is used to deduce if the session was opened with independent_channels
            #  set to True (in that case, the channel name would be fully-qualified) or False (in
            #  that case, the channel name would not have any instrument prefix). It is also used
            #  to extract the instrument prefix and populate the expanded channels repeated
            #  capabilities with it if needed
            first_channel_name = self._get_channel_names([0])[0]
            channel_names = _converters.convert_channels_repeated_capabilities(
                self._repeated_capability,
                first_channel_name
            )

        return [
            Measurement(
                voltage=voltage,
                current=current,
                in_compliance=${in_compliance_value},
                channel=${channel_name_value}
            ) for voltage, current${in_compliance_unpack}${channel_name_unpack} in zip(
                voltage_measurements, current_measurements${in_compliances_return}${channel_names_zipped}
            )
        ]

